include TireStoresHelper

# for onboarding...
class WelcomeController < ApplicationController
	before_filter :correct_ts_user,  :only => [:update_stripe, :registration_complete]

	def register
		@uuid ||= params[:uuid]

		if @uuid.blank?
			redirect_to :action => :no_record
			return
		end

		@distributor_import = DistributorImport.find_by_uuid(@uuid)
		if @distributor_import.nil?
			redirect_to :action => :no_record
			return
		end

		if @distributor_import.registered == true
			if @distributor_import.tire_store
				# are we currently signed in?
				if !signed_in?
					# login and redirect to markups
      				set_return_path('/welcome/set_markups?register=true')
      				redirect_to signin_path, notice: "This store has already registered.  Please sign in to continue."
      				return
				else
					@user = current_user
					if @user.tire_store_id == @distributor_import.tire_store_id
						# do they have markups?
						if true # check markups
							flash[:notice] = "This store has already registered.  Please enter markups now."
							redirect_to :action => :set_markups, :controller => :welcome, :register => true
							return true
						end
					else
						# invalid tire store
						redirect_to '/', notice: "You do not have access to that page."
						return
					end
				end
			else
				# we have registered but do not have a tire store - this is bad.
				redirect_to '/', notice: "There was a problem with this store's registration."
				return
			end
		end

		@distributor_import.clicked = true
		@distributor_import.clicked_at = Time.now
		@distributor_import.save

		if @account.nil? || @tire_store.nil? || @user.nil?
			@account, @tire_store, @user = @distributor_import.create_account_store_and_user
		end

		# OnBoardMailer.delay.on_board_email(current_user)
	end

	def show_register
		err_msg = ""
		@user.errors.each do |f, m|
			f = "Password" if f.to_s == "password_digest"
			err_msg += "#{f} #{m}<br />"
		end
		@tire_store.errors.each do |f, m|
			err_msg += "#{f} #{m}<br />"
		end
		@account.errors.each do |f, m|
			err_msg += "#{f} #{m}<br />"
		end
		flash[:notice] = err_msg
		render 'register'
	end

	def registration
		@account = Account.new(params[:user][:account])
		@tire_store = TireStore.new(params[:user][:tire_store])
		@user_params = params[:user].except(:tire_store, :account)
		@user = User.new(@user_params)
		@user.admin = 1
		@uuid = params[:uuid]

		@distributor_import = DistributorImport.find_by_uuid(@uuid)

		@user.tireseller = true

		if !@user.valid? || !@account.valid? || !@tire_store.valid?
			show_register
			return false
		end

		# first create the account...
		if @account.save
			@tire_store.account_id = @account.id
			@tire_store.distributor_import_id = @distributor_import.id
			if @tire_store.save
	        	@user.account_id = @account.id 
	        	@user.tire_store_id = @tire_store.id
	        	if @user.save
					sign_in @user

					@distributor_import.registered = true
					@distributor_import.registered_at = Time.now
					@distributor_import.tire_store_id = @tire_store.id
					@distributor_import.save

					redirect_to :action => :set_markups, :register => true
					return
				else
					@tire_store.delete
					@account.delete
					show_register
					return false
				end
			else
				# delete the account
				@account.delete
				show_register
				return false
			end
		else
			show_register
			return false
		end

		redirect_to :action => :set_markups, :register => true
		return
	end

	def update_stripe
		@tire_store = TireStore.find(params[:tire_store][:id])

		@tire_store.update_attributes(params[:tire_store])

		@account_token = params[:stripeAccountToken]
		@tax_id = params[:stripeTaxID]
		@business_name = params[:stripeBusinessName]
		@business_type = params[:stripeBusinessType]
		@online_payments = params[:online_payments]

		if @online_payments && @online_payments == "1"  && 
				@tire_store.stripe_account_id != @account_token
			if !@account_token.blank? && !@tax_id.blank? && !@business_name.blank? &&
				!@business_type.blank?

				begin
					@tire_store.update_stripe_recipient_data_bank_account(@business_name,
						@business_type, @tax_id, @account_token)
				rescue Exception => e 
				end
			end
		end

		@tire_store.branding.update_attributes(params[:branding])

		if !params[:open_24_hrs_monday].blank?
			@tire_store.monday_open = "00:00"
			@tire_store.monday_close = "23:59"
		elsif !params[:closed_monday].blank?
			@tire_store.monday_open = ""
			@tire_store.monday_close = ""
		elsif params[:tire_store][:monday_open].blank? && params[:tire_store][:monday_closed].blank?
			@tire_store.google_properties["monday_open"] = " "
			@tire_store.google_properties["monday_close"] = " "
		end

		if !params[:open_24_hrs_tuesday].blank?
			@tire_store.tuesday_open = "00:00"
			@tire_store.tuesday_close = "23:59"
		elsif !params[:closed_tuesday].blank?
			@tire_store.tuesday_open = ""
			@tire_store.tuesday_close = ""
		elsif params[:tire_store][:tuesday_open].blank? && params[:tire_store][:tuesday_closed].blank?
			@tire_store.google_properties["tuesday_open"] = " "
			@tire_store.google_properties["tuesday_close"] = " "
		end

		if !params[:open_24_hrs_wednesday].blank?
			@tire_store.wednesday_open = "00:00"
			@tire_store.wednesday_close = "23:59"
		elsif !params[:closed_wednesday].blank?
			@tire_store.wednesday_open = ""
			@tire_store.wednesday_close = ""
		elsif params[:tire_store][:wednesday_open].blank? && params[:tire_store][:wednesday_close].blank?
			@tire_store.google_properties["wednesday_open"] = " "
			@tire_store.google_properties["wednesday_close"] = " "
		end

		if !params[:open_24_hrs_thursday].blank?
			@tire_store.thursday_open = "00:00"
			@tire_store.thursday_close = "23:59"
		elsif !params[:closed_thursday].blank?
			@tire_store.thursday_open = ""
			@tire_store.thursday_close = ""
		elsif params[:tire_store][:thursday_open].blank? && params[:tire_store][:thursday_close].blank?
			@tire_store.google_properties["thursday_open"] = " "
			@tire_store.google_properties["thursday_close"] = " "
		end

		if !params[:open_24_hrs_friday].blank?
			@tire_store.friday_open = "00:00"
			@tire_store.friday_close = "23:59"
		elsif !params[:closed_friday].blank?
			@tire_store.friday_open = ""
			@tire_store.friday_close = ""
		elsif params[:tire_store][:friday_open].blank? && params[:tire_store][:friday_close].blank?
			@tire_store.google_properties["friday_open"] = " "
			@tire_store.google_properties["friday_close"] = " "
		end

		if !params[:open_24_hrs_saturday].blank?
			@tire_store.saturday_open = "00:00"
			@tire_store.saturday_close = "23:59"
		elsif !params[:closed_saturday].blank?
			@tire_store.saturday_open = ""
			@tire_store.saturday_close = ""
		elsif params[:tire_store][:saturday_open].blank? && params[:tire_store][:saturday_close].blank?
			@tire_store.google_properties["saturday_open"] = " "
			@tire_store.google_properties["saturday_close"] = " "
		end

		if !params[:open_24_hrs_sunday].blank?
			@tire_store.sunday_open = "00:00"
			@tire_store.sunday_close = "23:59"
		elsif !params[:closed_sunday].blank?
			@tire_store.sunday_open = ""
			@tire_store.sunday_close = ""
		elsif params[:tire_store][:sunday_open].blank? && params[:tire_store][:sunday_close].blank?
			@tire_store.google_properties["sunday_open"] = " "
			@tire_store.google_properties["sunday_close"] = " "
		end

		@tire_store.save

		# since we're connected to Stripe, we can create the listings
		# these records should have been created when the markups were created.
		if @tire_store.get_stripe_account_record != nil
			dt = WarehouseTier.find_by_warehouse_id_and_tier_name(@tire_store.distributor_import.warehouse.id, @tire_store.distributor_import.distributor_tier)
			tswt = TireStoreWarehouseTier.find_by_tire_store_id_and_warehouse_id_and_warehouse_tier_id(@tire_store.id, @tire_store.distributor_import.warehouse.id, dt.id)

			# finally, create the listings!
			tswt.delay.create_or_update_tire_listings

			flash[:notice] = "Thank you for providing the information to Stripe.  We are importing listings from the distributor now!"
		end

		redirect_to :action => :registration_complete
		return
	end

	def registration_complete
		if @tire_store.nil?
			@tire_store = current_user.tire_store
		end
	end

	def connect_with_stripe
		if !signed_in?
			# login and redirect to markups
			set_return_path(request.fullpath)  
			redirect_to signin_path, notice: "This store has already registered.  Please sign in to continue."
			return
		end

		if @user.nil?
			@user = current_user 
		end

		if @tire_store.nil?
			@tire_store = current_user.tire_store
		end

		if @account.nil?
			@account = @tire_store.account 
		end

		if @distributor_import.nil?
			@distributor_import = @tire_store.distributor_import
		end

		if @distributor.nil?
			@distributor = @distributor_import.distributor 
		end

		@warehouse = @distributor_import.warehouse

		@branding = Branding.find_or_create_by_tire_store_id(@tire_store.id)
	end

	def set_markups
		if !signed_in?
			# login and redirect to markups
			set_return_path(request.fullpath)  
			redirect_to signin_path, notice: "This store has already registered.  Please sign in to continue."
			return
		end

		if @user.nil?
			@user = current_user 
		end

		if @tire_store.nil?
			@tire_store = current_user.tire_store
		end

		if @account.nil?
			@account = @tire_store.account 
		end

		if @distributor_import.nil?
			@distributor_import = @tire_store.distributor_import
		end

		if @distributor.nil?
			@distributor = @distributor_import.distributor 
		end

		# sort the manufacturers by name, just for kicks
		@tire_manufacturers = @distributor.tire_manufacturers_list.sort{|a,b| a.name <=> b.name}

		@warehouse = @distributor_import.warehouse

		@markups = TireStoreMarkup.find(:all, :conditions => ['tire_store_id = ? and warehouse_id = ?', @tire_store.id, @warehouse.id])

		# if we don't have a default markup record for each manufacturer
		# that this distributor carries, create one.  Generally this markups
		# array is going to be empty anyway because we're calling it on a brand
		# new store but we might edit the existing markups as well.
		@tire_manufacturers.each do |manu|
			existing_markup = @markups.select {|m| m.tire_manufacturer_id == manu.id and m.tire_model_id.nil? and m.tire_size_id.nil? and m.tire_model_info_id.nil? and m.tire_category_id.nil?}.first
			@markups << TireStoreMarkup.new(:tire_manufacturer_id => manu.id, :markup_type => 0, :markup_pct => 20.0) if existing_markup.nil?
		end


		# REMOVE - this is for testing...
		if false
			@markups << TireStoreMarkup.new(:tire_manufacturer_id => TireManufacturer.find_by_name("Dunlop").id, 
								:tire_category_id => TireCategory.find_by_category_name("Grand Touring Summer").id,
								:markup_type => 0, :markup_pct => 15.0)
			@markups << TireStoreMarkup.new(:tire_manufacturer_id => TireManufacturer.find_by_name("Dunlop").id, 
								:tire_model_info_id => TireModelInfo.find_by_tire_model_name("Grandtrek PT1").id,
								:markup_type => 0, :markup_pct => 15.0)
		end


		@manu_markup_hash = {}
		@manu_tire_category_hash = {}
		@manu_tire_model_hash = {}
		@manu_tire_size_hash = {}

		# now create a hash with distributors and their sub-markups
		@tire_manufacturers.each_with_index do |manu, i|
			@manu_markup_hash[manu] = @markups.select{|m| m.tire_manufacturer_id == manu.id}

			distinct_categories = TireModel.find(:all, :select => "DISTINCT tire_category_id", :conditions => ["tire_manufacturer_id = ?", manu.id])
			@manu_tire_category_hash[manu] = TireCategory.find(:all, :conditions => ["id in (?)", distinct_categories.map{|m| m.tire_category_id}], :order => 'category_name')

			distinct_sizes = TireModel.find(:all, :select => "DISTINCT tire_size_id", :conditions => ["tire_manufacturer_id = ?", manu.id])
			@manu_tire_size_hash[manu] = TireSize.find(:all, :conditions => ["id in (?)", distinct_sizes.map{|m| m.tire_size_id}], :order => 'sizestr')

			@manu_tire_model_hash[manu] = TireModelInfo.find(:all, :conditions => ["tire_manufacturer_id = ?", manu.id], :order => 'tire_model_name')
		end
	end

	def no_record

	end
end