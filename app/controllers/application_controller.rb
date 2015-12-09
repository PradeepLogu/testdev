class ApplicationController < ActionController::Base
	protect_from_forgery
	include SessionsHelper
  include SimpleCaptcha::ControllerHelpers

	before_filter :redirect_if_dogtires
	before_filter :redirect_if_invalid_storefront
	before_filter :miniprofiler
	before_filter :clear_return_path
	before_filter :get_notifications

	helper_method :us_states

	def us_states
	[
	  ['Select a state', ''],
	  ['Alabama', 'AL'],
	  ['Alaska', 'AK'],
	  ['Arizona', 'AZ'],
	  ['Arkansas', 'AR'],
	  ['California', 'CA'],
	  ['Colorado', 'CO'],
	  ['Connecticut', 'CT'],
	  ['Delaware', 'DE'],
	  ['District of Columbia', 'DC'],
	  ['Florida', 'FL'],
	  ['Georgia', 'GA'],
	  ['Hawaii', 'HI'],
	  ['Idaho', 'ID'],
	  ['Illinois', 'IL'],
	  ['Indiana', 'IN'],
	  ['Iowa', 'IA'],
	  ['Kansas', 'KS'],
	  ['Kentucky', 'KY'],
	  ['Louisiana', 'LA'],
	  ['Maine', 'ME'],
	  ['Maryland', 'MD'],
	  ['Massachusetts', 'MA'],
	  ['Michigan', 'MI'],
	  ['Minnesota', 'MN'],
	  ['Mississippi', 'MS'],
	  ['Missouri', 'MO'],
	  ['Montana', 'MT'],
	  ['Nebraska', 'NE'],
	  ['Nevada', 'NV'],
	  ['New Hampshire', 'NH'],
	  ['New Jersey', 'NJ'],
	  ['New Mexico', 'NM'],
	  ['New York', 'NY'],
	  ['North Carolina', 'NC'],
	  ['North Dakota', 'ND'],
	  ['Ohio', 'OH'],
	  ['Oklahoma', 'OK'],
	  ['Oregon', 'OR'],
	  ['Pennsylvania', 'PA'],
	  ['Puerto Rico', 'PR'],
	  ['Rhode Island', 'RI'],
	  ['South Carolina', 'SC'],
	  ['South Dakota', 'SD'],
	  ['Tennessee', 'TN'],
	  ['Texas', 'TX'],
	  ['Utah', 'UT'],
	  ['Vermont', 'VT'],
	  ['Virginia', 'VA'],
	  ['Washington', 'WA'],
	  ['West Virginia', 'WV'],
	  ['Wisconsin', 'WI'],
	  ['Wyoming', 'WY']
	]
	end

	def clear_return_path
		set_return_path("")
	end

	def set_return_path(path)
		session[:return_to] = path
	end

	def get_notifications
		if !current_user.nil?
			@notifications = Notification.user_notifications(current_user.id)
			if !current_user.account.nil?
				@notifications = @notifications | Notification.public_account_notifications(current_user.account_id)
			end
			if !current_user.account.nil? && current_user.is_admin?
				@notifications = @notifications | Notification.admin_account_notifications(current_user.account_id)
			end
			if super_user?
				@notifications = @notifications | Notification.super_user_notifications
			end
		else
			@notifications = []
		end

		@notifications.each do |n|
			n.viewed()
		end
	end

	protected
		def redirect_if_dogtires
			if Rails.env.production? && request.host.downcase.include?('dogtires.com')
				redirect_to "http://www.treadhunter.com#{request.original_fullpath}", :status => :moved_permanently 
			end
		end

		def redirect_if_invalid_storefront
			if Rails.configuration.storefront_domain &&
				request.host.downcase.include?(Rails.configuration.storefront_domain.downcase)

				if !['www', 'beta'].include?(request.subdomain.downcase)
					# this is a storefront domain.  Let's validate the existence
					# of that storefront domain, if it doesn't exist we'll go to www
					if !TireStore.find_by_domain(request.subdomain.downcase)
						redirect_to "http://www.#{Rails.configuration.storefront_domain}:#{request.port}#{request.original_fullpath}", :status => :moved_permanently
					end 
				end
			end
		end
	private

	def miniprofiler
	  Rack::MiniProfiler.authorize_request if current_user && current_user.email == "kevin@irick.net" 
	end
end
