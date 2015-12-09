module ApplicationHelper
	def status_array
		{
		    :active    => 0,
		    :inactive  => 1, 
		    :expired   => 2, 
		    :deleted   => 3, 
		    :suspended => 4
		}
	end

	def order_status_array
		{
		    :completed          => 0,
		    :billed				=> 10,
		    :ready_for_billing  => 20,
		    :created            => 30,
		    :billing_failed     => 40,
		    :refunded           => 50,
		    :deleted            => 60,
		    :expired            => 70
		}
	end	

	def inventory_status_array
		{
		    :in_stock => 0,
		    :ordered  => 10,
		    :unknown  => 20
		}
	end	

	def authenticate
		if APP_CONFIG['perform_authentication']
			authenticate_or_request_with_http_basic("Treadhunter") do |username, password|
				(username == APP_CONFIG['username'] && password == APP_CONFIG['password']) ||
				(username == APP_CONFIG['username2'] && password == APP_CONFIG['password2'])
			end
		else
			return true
		end
	end

	def ask_for_bank_info
		if !Rails.env.production?
			return true
		else
			return false
		end
	end

	def special_pricing_plan_name
		"TreadHunter Special Pricing"
	end

	def private_seller_plan_name
		"TreadHunter Private Seller"
	end

	def platinum_plan_name
		"TreadHunter Platinum"
	end

	def gold_plan_name
		"TreadHunter Gold"
	end

	def silver_plan_name
		"TreadHunter Silver"
	end

	def free_trial_plan_name
		"TreadhHunter Free Trial"
	end

	def visfire_storemode
		APP_CONFIG['visfire_storemode']
	end

	def free_trial_days
		APP_CONFIG['free_trial_days'].to_i || 180
	end
  
	def free_trial_months
		APP_CONFIG['free_trial_months'].to_i || -1
	end
  
	def free_trial_verbiage
		if free_trial_months < 0
			"#{free_trial_days} days"
		elsif free_trial_months > 0
			"#{free_trial_months} months"
		else
			nil
		end
	end
  
	def free_trial_expiration
		if free_trial_months < 0
			if free_trial_days < 0
				return 0.seconds
			else
				return free_trial_days.days
			end
		else
			return free_trial_months.months
		end
	end

	def allow_ecomm
		APP_CONFIG['allow_ecomm'].to_s.to_bool || false
	end

	def allow_realtime_notifications
		APP_CONFIG['allow_realtime_notifications'].to_s.to_bool || false
	end

	def realtime_polling_frequence_ms
		APP_CONFIG['realtime_polling_frequence_ms'].to_i || 30000
	end

	def show_partners
		APP_CONFIG['show_partners'].to_s.to_bool || false
	end

	def beta_users
		APP_CONFIG['beta_users'] || []
	end

	def cl_blocked_users
		APP_CONFIG['cl_blocked_users'] || []
	end

	def collect_cc_upfront
		APP_CONFIG['collect_cc_upfront']
	end

	def create_contracts
		APP_CONFIG['create_contracts']
	end

	def secure_cc
		APP_CONFIG['secure_cc']
	end

	def backtrace_logging_enabled
		APP_CONFIG['backtrace_log']
	end

	def stripe_livemode
		APP_CONFIG['stripe_livemode']
	end

	def stripe_public_key
		ENV['PUBLISHABLE_KEY']
	end

	def google_places_api_key
		APP_CONFIG['google_places_api_key']
	end

	def google_docs_username
		APP_CONFIG['google_docs_username']
	end

	def google_docs_password
		APP_CONFIG['google_docs_password']
	end

	def google_docs_survey_doc_id
		APP_CONFIG['google_docs_survey_doc_id']
	end

	def google_docs_survey_form_id
		APP_CONFIG['google_docs_survey_form_id']
	end

	def system_problem_email_address
		APP_CONFIG['system_problem_email_address']
	end

	def system_problem_cc_email_address
		APP_CONFIG['system_problem_cc_email_address']
	end

	def system_problem_bcc_email_address
		APP_CONFIG['system_problem_bcc_email_address']
	end

	def customer_issue_email_address
		APP_CONFIG['customer_issue_email_address']
	end

	def customer_issue_cc_email_address
		APP_CONFIG['customer_issue_cc_email_address']
	end

	def customer_issue_bcc_email_address
		APP_CONFIG['customer_issue_bcc_email_address']
	end

  	def system_process_completion_email_address
  		APP_CONFIG['system_process_completion_email_address']
  	end

  	def system_process_completion_bcc_email_address
  		APP_CONFIG['system_process_completion_bcc_email_address']
  	end

	def backtrace_log
		if APP_CONFIG['backtrace_log']
			puts "#{DateTime.current.to_s} ******** #{caller[0]}"
			(2..5).each do |c|
				puts caller[c] unless caller[c].include?("actionpack")
			end
		end
	end

	def load_storefront
		puts "****ksi*** load_storefront"
		begin
	  		@tire_store = TireStore.find_by_domain(request.subdomain) unless ["www", "beta", ""].include?(request.subdomain.downcase)
	  	rescue
	  		@tire_store = nil
	  	end
	  	true
	end

	def in_storefront?
		return false
		begin
			result = !["www", "beta", ""].include?(request.subdomain.downcase)

			if result
				load_storefront
				if !@tire_store || @tire_store.private_seller?
					result = false
				end
			end
		rescue
			result = false
		end
		result
	end

	def redirect_to_back(default = root_url)
		if !request.env["HTTP_REFERER"].blank? and request.env["HTTP_REFERER"] != request.env["REQUEST_URI"]
			redirect_to :back
		else
			redirect_to default
		end
	end

	String.class_eval do
	    def is_valid_url?
	        uri = URI.parse self
	        uri.kind_of? URI::HTTP
	    rescue URI::InvalidURIError
	        false
	    end
	end

	STOREFRONT_COLORS = [{:key => 'infobox_background_color', :label => 'Panel background:', :default => '#FFFFFF'},
	                    {:key => 'infobox_border_color', :label => 'Panel border:', :default => '#000000'},
	                    {:key => 'body_text_color', :label => 'Body text:', :default => '#000000'},
	                    {:key => 'body_background_color', :label => 'Page background:', :default => '#EBEBEB'},
	                    {:key => 'storename_header_color', :label => 'Store name:', :default => '#FF0000'},
	                    {:key => 'storeaddress_header_color', :label => 'Address:', :default => '#FFFFFF'},
	                    {:key => 'footer_text_color', :label => 'Footer text:', :default => '#CCC'},
	                    {:key => 'box_title_color', :label => 'Panel title:', :default => '#000000'}]

	STOREFRONT_SIZES = [{:key => 'box_title_size', :label => 'Panel title:', :default => '1.33em', 
				:choices => [['Normal', '1em'], ['Enhanced (+33%)', '1.33em'], ['Large (+66%)', '1.66em'], ['Double', '2em']]}]
				
end
