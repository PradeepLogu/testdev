include TireListingsHelper
include InstallationCostsHelper

class InstallationCostsController < ApplicationController
	before_filter :has_posting_access
	before_filter :has_account_access

	def edit
		@account_id = params[:account_id]
		@tire_store_id = params[:tire_store_id]

		if current_user.nil?
          redirect_back_or root_path#, :alert => "Please sign in first."
          return
		end

		@size_choices = [13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27]

		@default_cost = []
		@size_choices.each do |s|
			@default_cost << InstallationCost.get_installation_cost(@account_id, @tire_store_id, s)
		end
	end

	def update_prices
		@tire_store_id = params[:tire_store_id].to_i ||= 0
		@account_id = params[:account_id].to_i ||= 0

		if @tire_store_id > 0 && @account_id <= 0
			@account_id = TireStore.find(@tire_store_id).account_id 
		end

		if @tire_store_id == 0 && @account_id == 0
			@account_id = current_user.account_id
			@tire_store_id = 0
		end

		if @account_id <= 0 && @tire_store_id <= 0
          redirect_back_or root_path, :alert => "Unable to update installation prices."
          return
		end

		params.each do |p, v|
			if p.start_with?('price_')
				wheel_diameter = p[6..99].to_i

				ic = InstallationCost.find_or_create_by_tire_store_id_and_account_id_and_min_wheel_diameter_and_max_wheel_diameter(@tire_store_id, @account_id, wheel_diameter, wheel_diameter)
				ic.ea_install_price = v
				ic.save
			end
		end

		redirect_to :action => :show_install_prices, :controller => :installation_costs, :account_id => @account_id, :tire_store_id => @tire_store_id
	end

	def show_install_prices
		@account_id = params[:account_id].to_i ||= current_user.account_id
		@account_wide_prices = InstallationCost.find(:all, :conditions => ["account_id = ? and tire_store_id = 0", @account_id], :order => 'min_wheel_diameter asc')
		@account = Account.find(@account_id)

		@tire_store_override_prices = []
		@tire_store_override_stores = []
		@account.tire_stores.each do |t|
			@cur_store_prices = InstallationCost.find(:all, :conditions => ["tire_store_id = ?", t.id], :order => 'min_wheel_diameter asc')
			if @cur_store_prices && @cur_store_prices.size > 0
				@tire_store_override_prices << @cur_store_prices
				@tire_store_override_stores << t
			end
		end
	end
end