# handles mobile requests, of the form /m/...
include TireStoresHelper

class MobileController < ApplicationController
  before_filter :sleep_a_while
  
  def sleep_a_while
    #sleep 30
  end

  def get_user_for_token_and_email(email)
    if params[:token]
      @user = User.find_by_mobile_token(token_decode(params[:token])) 
      @user = User.find_by_remember_token(token_decode(params[:token])) unless @user

      if @user && (@user.email.downcase == email.downcase)
        @user
      else
        nil
      end
    else
      nil
    end
  end
  
  def validate_token_for_tire_store(tire_store_id)
    if params[:token]
      @user = User.find_by_mobile_token(token_decode(params[:token])) 
      @user = User.find_by_remember_token(token_decode(params[:token])) unless @user

      if @user
        # we have a user, does he have access to this store?
        if @user.status == 2 # super user
          true
        else
          if tire_store_id
            @tire_store = TireStore.find_by_id_and_account_id(tire_store_id, @user.account_id)
            if @tire_store
              true
            else
              false
            end
          else
            false
          end
        end
      else
        false
      end
    else
      false
    end
  end

  def create_store
    errMsg = ""
    @email = URI.unescape(params[:encoded_email])
    @user = get_user_for_token_and_email(@email)
    if @user
      User.transaction do
        @account = @user.account
        if @account.nil?
          @account = Account.new
          @account.billing_email = @email
          @account.phone = params[:phone]
          @account.name = params[:name]
          @account.address1 = params[:address1]
          @account.address2 = params[:address2]
          @account.city = params[:city]
          @account.state = params[:state]
          @account.zipcode = params[:zipcode]
          @account.zipcode = params[:zip_code] if @account.zipcode.blank?

          if !@account.save
            @account.errors.each do |a, b|
              errMsg += "-->#{a.to_s} - #{b.to_s}"
            end
            raise ActiveRecord::Rollback
          end
        end

        @tire_store = TireStore.new
        @tire_store.name = params[:name]
        @tire_store.account_id = @account.id
        @tire_store.contact_email = @email
        @tire_store.phone = params[:phone]
        @tire_store.address1 = params[:address1]
        @tire_store.address2 = params[:address2]
        @tire_store.city = params[:city]
        @tire_store.state = params[:state]
        @tire_store.zipcode = params[:zipcode]
        @tire_store.zipcode = params[:zip_code] if @tire_store.zipcode.blank?
        @tire_store.private_seller = false
        @tire_store.hide_phone = false

        if !@tire_store.save
          @tire_store.errors.each do |a, b|
            errMsg += "-->#{a.to_s} - #{b.to_s}"
          end
          raise ActiveRecord::Rollback
        end

        if !@user.update_attribute(:account_id, @account.id)
          @user.errors.each do |a, b|
            errMsg += "#{a.to_s} - #{b.to_s}<br />"
          end
          raise ActiveRecord::Rollback
        end
      end
      if errMsg.blank?
        respond_to do |format|
          format.json { render json: @tire_store.to_json }
        end
      else
        respond_to do |format|
          format.json { render json: errMsg.to_json, status: 600 }
        end
      end
    else
      render :file => "public/422.html", :status => :internal_server_error
    end
  end

  def register_user
    @user = User.new
    @user.email = params[:email]
    @user.email = params[:email_address] if @user.email.nil?
    @user.password = token_decode(params[:password])
    @user.password_confirmation = token_decode(params[:password_confirmation])
    @user.first_name = params[:first_name]
    @user.last_name = params[:last_name]
    @user.phone = params[:phone]
    @user.tireseller = params[:tireseller]

    @store_type = params[:store_type]

    if @user.save
      if @store_type == 2 # private seller
      else
        respond_to do |format|
          @user.set_mobile_token
          puts "I am returning a mobile token of #{@user.public_mobile_token}"
          format.json { render json: @user.to_json(:methods => [:public_mobile_token]) }
        end
      end
    else
      respond_to do |format|
        errMsg = ""
        @user.errors.each do |a, b|
          errMsg += "#{a} #{b}<br />"
        end
        format.json { render json: errMsg.to_json, status: 600 }
      end
    end
  end

  # /tire-store/:tire_store_id/tire-listings.json
  def store_listings
    @tire_store = TireStore.find(params[:tire_store_id])
    @search_filter = CGI.unescape(params[:search_filter])
    if @tire_store
      respond_to do |format|
        if !@search_filter.blank?
          format.json { render :json => @tire_store.mobile_tire_listings_filtered(@search_filter).sort_by{|l| l[:id]}, :except => [:price], 
          :methods => [:realtime_quote_distributors, :short_description, :formatted_price, :photo1_thumbnail, 
                      :photo2_thumbnail, :photo3_thumbnail, :photo4_thumbnail,
                      :manufacturer_name, :model_name, :sizestr, :cl_title,
                      :photo1_small, :photo2_small, :photo3_small, :photo4_small]}
        else
          # format.json { render json: @tire_store.mobile_tire_listings.to_json }
          format.json { render :json => @tire_store.mobile_tire_listings.sort_by{|l| l[:id]}, :except => [:price], 
          :methods => [:realtime_quote_distributors, :short_description, :formatted_price, :photo1_thumbnail, 
                      :photo2_thumbnail, :photo3_thumbnail, :photo4_thumbnail,
                      :manufacturer_name, :model_name, :sizestr, :cl_title,
                      :photo1_small, :photo2_small, :photo3_small, :photo4_small]}
        end
      end
    end
  rescue
    render :file => "public/422.html", :status => :internal_server_error
  end

  def tire_sizes
    w = TireSize.find(:all)
    if w
      respond_to do |format|
        format.json { render json: w.to_json }
      end
    end
  rescue
    render :file => "public/422.html", :status => :internal_server_error
  end

  def create_test_notifications_android
    @decoded_email = token_decode(params[:base64_email]).downcase
    Device.CreateTestMessagesAndroid(@decoded_email)
    respond_to do |format|
      format.json { render json: "ok".to_json }
    end
  end

  # match '/m/show_notification/:device/:tire_store_id/:base64_email/:token/:guid.:format'
  def show_notification
    ###@decoded_email = token_decode(params[:base64_email]).downcase
    @encoded_device = params[:device]
    @tire_store_id = params[:tire_store_id]
    @guid = params[:guid]

    # see if we can find a notification
    @notification = Device.find_push_message_by_guid(@guid)
    if @notification
      if validate_token_for_tire_store(@tire_store_id)
        # we have a notification and our user is valid for this store...make sure this is the right store
        if @tire_store_id.to_s == @notification.tire_store_id
          respond_to do |format|
            ##format.json { render :json => @notification, :methods => [:properties_json, :attributes_for_device_json] }
            format.json { render json: @notification.as_json(:methods => [:app, :type]) }
          end
        else
          render :file => "public/422.html", :status => :internal_server_error
        end
      else
        render :file => "public/422.html", :status => :internal_server_error
      end
    else
      render :file => "public/422.html", :status => :internal_server_error
    end

  rescue Exception => e
    puts "EXCEPTION!!! #{e.to_s} #{e.backtrace}"
    render :file => "public/422.html", :status => :internal_server_error
  end

  def widths
    w = TireSize.all_diameters
    if w
      respond_to do |format|
        format.json { render json: w.to_json }
      end
    end
  rescue
    render :file => "public/422.html", :status => :internal_server_error
  end

  def ratios
    r = TireSize.all_ratios(nil)
    if r
      respond_to do |format|
        format.json { render json: r.to_json }
      end
    end
  rescue
    render :file => "public/422.html", :status => :internal_server_error
  end

  def wheel_diameters
    r = TireSize.all_wheeldiameters(nil)
    if r
      respond_to do |format|
        format.json { render json: r.to_json }
      end
    end
  rescue
    render :file => "public/422.html", :status => :internal_server_error
  end

  # /branding/:tire_store_id.json
  def branding
    @branding = Branding.find_by_tire_store_id(params[:tire_store_id])
    if @branding
      respond_to do |format|
        format.json { render json: @branding.to_json }
      end
    end
  rescue
    render :file => "public/422.html", :status => :internal_server_error
  end
  
  def find_promotions_for_store
    @tire_store = TireStore.find(params[:tire_store_id])
    
  	query = "INSERT INTO impressions (impressionable_type, ip_address, controller_name, impressionable_id, action_name, created_at, updated_at) VALUES ('TireStore', '#{request.remote_ip}','mobile',#{@tire_store.id},'view','#{Time.now}','#{Time.now}');"
    ActiveRecord::Base.connection.execute(query);
    
    respond_to do |format|
      format.json { render json: @tire_store.as_json(:include  => [:non_national_promotions => {:methods => [:promo_attachment_url, :promo_attachment_file_name, :promo_image_url, :full_description]}], :methods => [:logo_url, :visible_phone, :full_address, :th_customer])}
    end    
  end
  
  def find_promotions
    lat = params[:latitude].gsub(/_/, '.')
    lon = params[:longitude].gsub(/_/, '.')
    
    @tire_stores = TireStore.near([lat, lon], 10).where(["private_seller = ?", false])
    
    @tire_stores.each do |t|
  		query = "INSERT INTO impressions (impressionable_type, ip_address, controller_name, impressionable_id, action_name, created_at, updated_at) VALUES ('TireStore', '#{request.remote_ip}','mobile',#{t.id},'appear_on_map','#{Time.now}','#{Time.now}');"
  		ActiveRecord::Base.connection.execute(query);
    end
    
    respond_to do |format|
      format.json { render json: @tire_stores.as_json(:include  => [:promotions], :methods => [:visible_phone, :full_address, :logo_url, :th_customer])}
    end
  end
  
  def combine_stores_for_list
    lat = params[:latitude].gsub(/_/, '.')
    lon = params[:longitude].gsub(/_/, '.')
    
    @tire_stores = ScrapeTireStore.search_all_stores(lat, lon, 20, "", 0, 50)
    
    @tire_stores.each do |t|
      if t.th_customer
        query = "INSERT INTO impressions (impressionable_type, ip_address, controller_name, impressionable_id, action_name, created_at, updated_at) VALUES ('TireStore', '#{request.remote_ip}','mobile',#{t.id},'appear_on_map','#{Time.now}','#{Time.now}');"        
      else
        query = "INSERT INTO impressions (impressionable_type, ip_address, controller_name, impressionable_id, action_name, created_at, updated_at) VALUES ('ScrapeTireStore', '#{request.remote_ip}','mobile',#{t.id},'appear_on_map','#{Time.now}','#{Time.now}');"
      end
  		ActiveRecord::Base.connection.execute(query) unless t.id.nil?
    end
    
    respond_to do |format|
      format.json { render json: @tire_stores.as_json(:include  => [:non_national_promotions], :except => [:google_properties, :th_customer_sql], :methods => [:external_url, :visible_phone, :full_address, :logo_url, :th_customer, :today_hours, :consumer_rating, :consumer_rating_count])}
    end
  end
  
  def find_scraped_stores
    lat = params[:latitude].gsub(/_/, '.')
    lon = params[:longitude].gsub(/_/, '.')
    
    @tire_stores = ScrapeTireStore.near([lat, lon], 10)
    
    @tire_stores.each do |t|
#      impressionist(t, "map")
  		query = "INSERT INTO impressions (impressionable_type, ip_address, controller_name, impressionable_id, action_name, created_at, updated_at) VALUES ('ScrapeTireStore', '#{request.remote_ip}','mobile',#{t.id},'appear_on_map','#{Time.now}','#{Time.now}');"
  		ActiveRecord::Base.connection.execute(query);
    end
    
    respond_to do |format|
      format.json { render json: @tire_stores.as_json(:methods => [:visible_phone, :full_address, :logo_url, :th_customer])}
    end
  end
  
  def find_non_national_promotions
    lat = params[:latitude].gsub(/_/, '.')
    lon = params[:longitude].gsub(/_/, '.')
    
    @tire_stores = TireStore.near([lat, lon], 10).where(["private_seller = ?", false])
    
    @tire_stores.each do |t|
  		query = "INSERT INTO impressions (impressionable_type, ip_address, controller_name, impressionable_id, action_name, created_at, updated_at) VALUES ('TireStore', '#{request.remote_ip}','mobile',#{t.id},'appear_on_map','#{Time.now}','#{Time.now}');"
  		ActiveRecord::Base.connection.execute(query);
    end    
    
    respond_to do |format|
      format.json { render json: @tire_stores.as_json(:include  => [:non_national_promotions], :methods => [:visible_phone, :full_address, :logo_url, :th_customer])}
    end
  end
  
#  match '/m/auto_manufacturers.:format', :to => 'mobile#auto_manufacturers'
#  match '/m/auto_models/:auto_manufacturer_id.:format', :to => 'mobile#auto_models'
#  match '/m/auto_years/:auto_model_id.:format', :to => 'mobile#auto_years'
#  match '/m/auto_options/:auto_year_id.:format', :to => 'mobile#auto_options'
  
  def auto_manufacturers
    @manu = AutoManufacturer.find(:all, :order => :name)
    
    respond_to do |format|
      format.json { render json: @manu }
    end
  end
  
  def auto_models
    @models = AutoModel.where("auto_manufacturer_id = ?", params[:auto_manufacturer_id]).order(:name)
    
    respond_to do |format|
      format.json { render json: @models }
    end
  end
  
  def auto_years
    @years = AutoYear.where("auto_model_id = ?", params[:auto_model_id]).order("auto_years.modelyear DESC")
    
    respond_to do |format|
      format.json { render json: @years }
    end
  end
  
  def auto_options
    @options = AutoOption.where("auto_year_id = ?", params[:auto_year_id]).order(:name)
    
    respond_to do |format|
      format.json { render json: @options }
    end
  end
  
  #match '/m/:make/:model/:year/:option/find_size.:format', :to => 'mobile#find_size'
  def find_size
    manu = AutoManufacturer.find_by_name(CGI.unescape(params[:make]))
    model = AutoModel.find_by_auto_manufacturer_id_and_name(manu.id, CGI.unescape(params[:model]))
    year = AutoYear.find_by_auto_model_id_and_modelyear(model.id, CGI.unescape(params[:year]))
    option = AutoOption.find_by_auto_year_id_and_name(year.id, CGI.unescape(params[:option]))
    size = TireSize.find(option.tire_size_id)
    
    respond_to do |format|
      format.json { render json: size }
    end
  end

  def find_store
    @tire_store = TireStore.find(params[:tire_store_id])
    respond_to do |format|
      format.json { render json: @tire_store, :methods => [:sunday_open, :sunday_close, :monday_open, :monday_close, :tuesday_open, :tuesday_close, :wednesday_open, :wednesday_close, :thursday_open, :thursday_close, :friday_open, :friday_close, :saturday_open, :saturday_close, :closed_all_day_array, :open_all_day_array, :realtime_quote_distributors, :logo_url, :th_customer] }
    end
  rescue
    render :file => "public/422.html", :status => :internal_server_error
  end

  def store_order
    if true || validate_token_for_tire_store(params[:tire_store_id])
      @order = Order.find(params[:order_id])
      if @order.tire_store.id.to_s != params[:tire_store_id]
        render :file => "public/422.html", :status => :unauthorized
      else
        respond_to do |format|
          format.json { render json: @order, :except => [:sales_tax_collected, :th_processing_fee, 
                :th_sales_tax_collected, :th_user_fee, :transfer_amount, :tire_ea_price, 
                :stripe_properties, :transfer_id, :other_properties, :inv_status],
                :methods => [:sales_tax_collected_money, :th_processing_fee_money, :th_sales_tax_collected_money,
                  :th_user_fee_money, :transfer_amount_money, :tire_ea_price_money, 
                  :total_tire_price, :total_install_price, :total_order_price, :tire_description] }
        end
      end
    else
      render :file => "public/422.html", :status => :unauthorized
    end
  end

  def store_order_stats
    if validate_token_for_tire_store(params[:tire_store_id])
      @tire_store = TireStore.find(params[:tire_store_id])
      respond_to do |format|
        format.json { render json: @tire_store, :only => [:id], :methods => [:order_count_ytd, :order_amount_ytd, :order_revenue_ytd, 
                      :order_count_mtd, :order_amount_mtd, :order_revenue_mtd, :order_count_wtd, :order_amount_wtd,
                      :order_revenue_wtd,
                      :get_weekly_order_history, :get_monthly_order_history, :get_yearly_order_history]}
      end
    else
      render :file => "public/422.html", :status => :unauthorized
    end
  end
  
  def find_stores
    @user = User.find_by_mobile_token(token_decode(params[:token])) 
    @user = User.find_by_remember_token(token_decode(params[:token])) unless @user
    if @user
      #find all (well, top 25) stores for this user
      lat = params[:latitude].gsub(/_/, '.')
      lon = params[:longitude].gsub(/_/, '.')
      searchstr = params[:searchstr]
      if searchstr == 'nil'
        searchstr = ''
      end
      searchstr = CGI.unescape(searchstr)
      if lat.to_i == 0 and lon.to_i == 0
        if @user.status == 2 # super user
          @tire_stores = TireStore.find(:all, :conditions => ["name ~* ?", searchstr], :limit => 50)
        else
          @tire_stores = TireStore.find(:all, :conditions => ["name ~* ? and account_id = ?", searchstr, @user.account_id], :limit => 50)
        end
      else
        if @user.status == 2 # super user
          @tire_stores = TireStore.near([lat, lon], 25000).find(:all, :conditions => ["name ~* ?", searchstr], :limit => 50)
        else
          @tire_stores = TireStore.near([lat, lon], 25000).find(:all, :conditions => ["name ~* ? and account_id = ?", searchstr, @user.account_id], :limit => 50)
        end
      end

      respond_to do |format|
        format.json { render json: @tire_stores, :methods => [:sunday_open, :sunday_close, :monday_open, :monday_close, :tuesday_open, :tuesday_close, :wednesday_open, :wednesday_close, :thursday_open, :thursday_close, :friday_open, :friday_close, :saturday_open, :saturday_close, :closed_all_day_array, :open_all_day_array, :realtime_quote_distributors, :logo_url, :th_customer] }
      end
    end
  rescue
    render :file => "public/422.html", :status => :internal_server_error
  end

  def realtime_price_quote
    # currently only supporting TCI
    @tci = Distributor.find_by_distributor_name_and_city('Tire Centers, LLC', 'Norcross')
    if @tci.nil?
      render :file => "public/422.html", :status => :internal_server_error
      return
    end

    @user = User.find_by_mobile_token(token_decode(params[:token])) 
    @user = User.find_by_remember_token(token_decode(params[:token])) unless @user
    if @user
      @tire_model_id = params[:tire_model_id]
      @tire_store_id = params[:tire_store_id]

      @tire_store = TireStore.find(@tire_store_id)
      @tire_model = TireModel.find(@tire_model_id)

      if @tire_store && @tire_model
        @tci_interface = TCIInterface.new
        @price_quote = @tci_interface.realtime_price_quote(@tire_store_id, @tire_model_id)

        if @price_quote.nil?
          render :file => "public/422.html", :status => :internal_server_error
          return
        else
          respond_to do |format|
            format.json { render json: @price_quote.to_json }
          end
        end
      else
        render :file => "public/422.html", :status => :internal_server_error
        return
      end
    else
      render :file => "public/422.html", :status => :internal_server_error
      return
    end
  end

  def load_reservation
    if validate_token_for_tire_store(params[:tire_store_id])
      @reservation = Reservation.find(params[:reservation_id])
      respond_to do |format|
        format.json { render json: @reservation.to_json(:methods => [:listing_description, :listing_price]) }
      end
    else
      render :file => "public/422.html", :status => :unauthorized
    end
  rescue
    render :file => "public/422.html", :status => :internal_server_error
  end

  # GET /m/:token/:tire_store_id/reservations.json
  def reservations
    if validate_token_for_tire_store(params[:tire_store_id])
      @tire_store = TireStore.find(params[:tire_store_id])
      @reservations = @tire_store.reservations.order("created_at DESC")
      respond_to do |format|
        format.json { render json: @reservations.to_json(:methods => [:photo1_url, :listing_description, :listing_price]) }
      end
    else
      render :file => "public/422.html", :status => :unauthorized
    end
  rescue
    render :file => "public/422.html", :status => :internal_server_error
  end

  # match '/m/:token/load_appointment/:appt_id.:format'
  def load_appointment
    @appt = Appointment.find_by_id(params[:appt_id])
    if @appt
      if validate_token_for_tire_store(@appt.tire_store_id)
        respond_to do |format|
          format.json { render json: @appt.to_json(:methods => [:tire_description, :order_price, :formatted_price, :confirmed_time, :primary_request_time, :secondary_request_time, :vehicle_name, :services_list]) }
        end
      else
        render :file => "public/422.html", :status => :unauthorized
      end
    else
      render :file => "public/422.html", :status => :unauthorized
    end
  end

  # match '/m/:token/:tire_store_id/reservations/:reference_date.:format', :to => 'mobile#tire_store_appointments'
  def tire_store_appointments
    if validate_token_for_tire_store(params[:tire_store_id])
      @query_date = Date.parse(params[:reference_date])
      @appointments = Appointment.store_appointments(params[:tire_store_id], @query_date)

      respond_to do |format|
        format.json { render json: @appointments.to_json(:methods => [:tire_description, :order_price, :formatted_price, :order_id, :formatted_price, :confirmed_time, :primary_request_time, :secondary_request_time, :vehicle_name, :services_list]) }
      end
    else
      render :file => "public/422.html", :status => :unauthorized
    end
  rescue
    render :file => "public/422.html", :status => :internal_server_error
  end

  def tire_store_appointments_range
    if validate_token_for_tire_store(params[:tire_store_id])
      @query_date = Date.parse(params[:reference_date])
      @days_ahead = params[:days_ahead].to_i
      @appointments = Appointment.store_appointments_with_range(params[:tire_store_id], @query_date, @days_ahead)

      respond_to do |format|
        format.json { render json: @appointments.to_json(:methods => [:tire_description, :order_price, :formatted_price, :order_id, :formatted_price, :confirmed_time, :primary_request_time, :secondary_request_time, :vehicle_name, :services_list]) }
      end
    else
      render :file => "public/422.html", :status => :unauthorized
    end
  rescue
    render :file => "public/422.html", :status => :internal_server_error
  end  

  def confirm_appointment_primary
    @appointment = Appointment.find(params[:appt_id])
    if @appointment
      @tire_store_id = @appointment.tire_store_id
      if validate_token_for_tire_store(@tire_store_id)
        @appointment.confirm_primary_appointment()

        respond_to do |format|
          format.json { render json: @appointment.to_json(:methods => [:formatted_price, :confirmed_time, :primary_request_time, :secondary_request_time, :vehicle_name, :services_list]) }
        end
      else
        render :file => "public/422.html", :status => :unauthorized
      end
    else
      render :file => "public/422.html", :status => :internal_server_error
    end
  rescue Exception => e
    puts "*** confirm_appointment_primary failed - #{e.to_s}"
    render :file => "public/422.html", :status => :internal_server_error
  end

  def reject_appointment
    @appointment = Appointment.find(params[:appt_id])
    if @appointment
      @tire_store_id = @appointment.tire_store_id
      if validate_token_for_tire_store(@tire_store_id)
        @appointment.reject_appointment

        respond_to do |format|
          format.json { render json: @appointment.to_json(:methods => [:formatted_price, :confirmed_time, :primary_request_time, :secondary_request_time, :vehicle_name, :services_list]) }
        end
      else
        render :file => "public/422.html", :status => :unauthorized
      end
    else
      render :file => "public/422.html", :status => :internal_server_error
    end
  rescue Exception => e
    render :file => "public/422.html", :status => :internal_server_error
  end

  def confirm_appointment_secondary
    @appointment = Appointment.find(params[:appt_id])
    if @appointment
      @tire_store_id = @appointment.tire_store_id
      if validate_token_for_tire_store(@tire_store_id)
        @appointment.confirm_primary_appointment()

        respond_to do |format|
          format.json { render json: @appointment.to_json(:methods => [:formatted_price, :confirmed_time, :primary_request_time, :secondary_request_time, :vehicle_name, :services_list]) }
        end
      else
        render :file => "public/422.html", :status => :unauthorized
      end
    else
      render :file => "public/422.html", :status => :internal_server_error
    end
  rescue Exception => e
    render :file => "public/422.html", :status => :internal_server_error
  end

  def tire_listing
    @tire_listing = TireListing.find(params[:id])
    respond_to do |format|
      format.json { render :json => @tire_listing, :except => [:price], 
              :methods => [:short_description, :formatted_price, :photo1_thumbnail, 
                          :photo2_thumbnail, :photo3_thumbnail, :photo4_thumbnail,
                          :manufacturer_name, :model_name, :sizestr, :cl_title]}
    end
  end

  # GET /m/:token/:tire_store_id/tire_listings.json
  def tire_listings
    if validate_token_for_tire_store(params[:tire_store_id])
      @tire_store = TireStore.find(params[:tire_store_id])
      @tire_store.sort_order = SortOrder::SORT_BY_MANU_ASC
      @tire_store.exclude_generic_filter = true
      @tire_listings = @tire_store.mobile_tire_listings #find_tirelistings
      respond_to do |format|
        format.json { render :json => @tire_listings.sort_by{|l| l[:id]}, :except => [:price], 
                :methods => [:realtime_quote_distributors, :short_description, :formatted_price, :photo1_thumbnail, 
                            :photo2_thumbnail, :photo3_thumbnail, :photo4_thumbnail,
                            :manufacturer_name, :model_name, :sizestr, :cl_title,
                            :photo1_small, :photo2_small, :photo3_small, :photo4_small]}
      end
    else
      render :file => "public/422.html", :status => :unauthorized
    end
  #rescue Exception => e 
  #  puts "*** Exception: #{e.to_s}"
  #  render :file => "public/422.html", :status => :internal_server_error
  end

  # /m/:token/cl_template/:tire_listing_id.:format
  def cl_template
    l = TireListing.find(params[:tire_listing_id])
    if l
      if validate_token_for_tire_store(l.tire_store_id)
        # we have a good match here - this user is able to see stuff for this store
        my_template = ClTemplate.find_by_account_id_and_tire_store_id(l.tire_store.account_id, l.tire_store_id)
        if !my_template
          # create from default
          default_template = ClTemplate.find_by_account_id_and_tire_store_id(0, 0)
          my_template = default_template.dup
          my_template.account_id = l.tire_store.account_id
          my_template.tire_store_id = l.tire_store.id
          my_template.save
        end
        my_template.tire_listing = l

        respond_to do |format|
          a = Array.new
          a << my_template
          format.json { render :json => my_template }
        end
      else
        render :file => "public/422.html", :status => :unauthorized
      end
    end
  rescue
    render :file => "public/422.html", :status => :internal_server_error
  end

  def mobile_template
    if validate_token_for_tire_store(params[:tire_store_id])
      @tire_store = TireStore.find(params[:tire_store_id])
      @template = @tire_store.cl_template

      if @template
        respond_to do |format|
          # gotta turn the single item into an array...long story
          a = Array.new
          a << @template
          format.json { render json: a }
        end
      end
    else
      render :file => "public/422.html", :status => :unauthorized
    end
  rescue
    render :file => "public/422.html", :status => :internal_server_error
  end

  def delete_reservation
    if validate_token_for_tire_store(params[:tire_store_id])
      @reservation = Reservation.find(params[:id])
      if @reservation
        if @reservation.tire_store.id = params[:tire_store_id]
          @reservation.cancel_reservation(CancelParty::SELLER)
          @reservation.destroy

          respond_to do |format|
            format.json { render json: @reservation.to_json(:methods => [:listing_description, :listing_price]) }            
          end
        end
      else
        render :file => "public/404.html", :status => 404
      end
    else
      render :file => "public/422.html", :status => :unauthorized
    end
  rescue
    render :file => "public/422.html", :status => :internal_server_error
  end

  def delete_tire_listing
    if validate_token_for_tire_store(params[:tire_store_id])
      @tire_listing = TireListing.find(params[:id])
      if @tire_listing
        if @tire_listing.tire_store.id = params[:tire_store_id]
          @tire_listing.destroy

          respond_to do |format|
            format.json { render :json => @tire_listing, :except => [:price], 
                    :methods => [:short_description, :formatted_price, :photo1_thumbnail, 
                                :photo2_thumbnail, :photo3_thumbnail, :photo4_thumbnail,
                                :manufacturer_name, :model_name, :sizestr, :cl_title]}
          end
        end
      end
    else
      render :file => "public/422.html", :status => :unauthorized
    end
  rescue
    render :file => "public/422.html", :status => :internal_server_error
  end

  def create_tire_listing
    if validate_token_for_tire_store(params[:tire_store_id])
      updateParams = params[:tire_listing]
      if updateParams.nil?
        updateParams = params[:mobile]
      end

      if updateParams.class.to_s == "String"
        updateParams = JSON.parse(updateParams)
      end
      @tire_listing = TireListing.new(updateParams)

      unless params["file1.png"].nil?
        @tire_listing.photo1 = params["file1.png"]
        mobile_mode = true
      else
        @tire_listing.photo1 = nil
      end

      unless params["file2.png"].nil?
        @tire_listing.photo2 = params["file2.png"]
        mobile_mode = true
      else
        @tire_listing.photo2 = nil
      end

      unless params["file3.png"].nil?
        @tire_listing.photo3 = params["file3.png"]
        mobile_mode = true
      else
        @tire_listing.photo3 = nil
      end

      unless params["file4.png"].nil?
        @tire_listing.photo4 = params["file4.png"]
        mobile_mode = true
      else
        @tire_listing.photo4 = nil
      end

      @tire_listing.source = "mobile" 

      respond_to do |format|
        if @tire_listing.save         
          format.html { render json: @tire_listing, status: :created, location: @tire_listing }
          format.json { render :json => @tire_listing, :except => [:price], 
                  :methods => [:short_description, :formatted_price, :photo1_thumbnail, 
                              :photo2_thumbnail, :photo3_thumbnail, :photo4_thumbnail,
                              :manufacturer_name, :model_name, :sizestr, :cl_title]}
        else
          @tire_listing.errors.each do |a, b|
            puts "*** #{a} #{b}"
          end
          format.html
          format.json { render json: @tire_listing.errors, status: :unprocessable_entity }
        end
      end
    else
      render :file => "public/422.html", :status => :unauthorized
    end
  rescue Exception => e
    puts "Exception: #{e.message}"
    e.backtrace.each do |msg|
      puts msg
    end
    render :file => "public/422.html", :status => :internal_server_error
  end

  # /m/:token/:tire_store_id/update_tire_listing_photo/:photo/:id.:format'
  def update_tire_listing_photo
    if validate_token_for_tire_store(params[:tire_store_id])
      @tire_listing = TireListing.find(params[:id])
      @compress = false
      mobile_mode = true

      begin
        @photo_num = params[:photo].to_i 
      rescue
        @photo_num = -1
      end

      if @photo_num == 1
        @tire_listing.photo1 = params["photo.png"]
      elsif @photo_num == 2
        @tire_listing.photo2 = params["photo.png"]
      elsif @photo_num == 3
        @tire_listing.photo3 = params["photo.png"]
      elsif @photo_num == 4
        @tire_listing.photo4 = params["photo.png"]
      else
        render :text => "oops"
        return
      end

      @tire_listing.save

      render :text => 'OK'
    else
      render :file => "public/422.html", :status => :internal_server_error
    end
  rescue Exception => e
    render :file => "public/422.html", :status => :internal_server_error
  end

  def update_tire_listing
    if validate_token_for_tire_store(params[:tire_store_id])
      @tire_listing = TireListing.find(params[:id])

      @compress = false

      unless params["file1.png"].nil?
        @tire_listing.photo1 = params["file1.png"]
        mobile_mode = true
        @compress = true
      end

      unless params["file1.jpg"].nil?
        @tire_listing.photo1 = params["file1.jpg"]
        mobile_mode = true
        @compress = true
      end

      unless params["delete1.png"].nil? && params["delete1.jpg"].nil?
        @tire_listing.photo1 = nil
        mobile_mode = true
        @compress = true
      end

      unless params["file2.png"].nil?
        @tire_listing.photo2 = params["file2.png"]
        mobile_mode = true
        @compress = true
      end

      unless params["file2.jpg"].nil?
        @tire_listing.photo2 = params["file2.jpg"]
        mobile_mode = true
        @compress = true
      end

      unless params["delete2.png"].nil? && params["delete2.jpg"].nil?
        @tire_listing.photo2 = nil
        mobile_mode = true
        @compress = true
      end

      unless params["file3.png"].nil?
        @tire_listing.photo3 = params["file3.png"]
        mobile_mode = true
        @compress = true
      end

      unless params["file3.jpg"].nil?
        @tire_listing.photo3 = params["file3.jpg"]
        mobile_mode = true
        @compress = true
      end

      unless params["delete3.png"].nil? && params["delete3.jpg"].nil?
        @tire_listing.photo3 = nil
        mobile_mode = true
        @compress = true
      end

      unless params["file4.png"].nil?
        @tire_listing.photo4 = params["file4.png"]
        mobile_mode = true
        @compress = true
      end

      unless params["file4.jpg"].nil?
        @tire_listing.photo4 = params["file4.jpg"]
        mobile_mode = true
        @compress = true
      end

      unless params["delete4.png"].nil? && params["delete4.jpg"].nil?
        @tire_listing.photo4 = nil
        mobile_mode = true
        @compress = true
      end

      @tire_listing.source = "mobile" 

      #@tire_listing.photo2 = open("http://s3.amazonaws.com/tirepicturesbeta/tire_listings/photo2s/002/161/682/original/file2.png")
      #@compress = false
      @tire_listing.save

      # now let's compress the array - if we have slots 1 and 3 occupied, 
      # let's move 3 to 2.  Etc...

      respond_to do |format|

        updateParams = params[:tire_listing]
        if updateParams.nil?
          updateParams = params[:mobile]
        end

        if updateParams.class.to_s == "String"
          updateParams = JSON.parse(updateParams)
        end

        if !updateParams.nil? &&
          updateParams.count > 0
          @tire_listing.update_attributes(updateParams)
        end

        if @compress 
          puts "***** BEFORE COMPRESS"
          backtrace_log if backtrace_logging_enabled
          @tire_listing.compress_photo_array
          puts "***** AFTER COMPRESS"
          backtrace_log if backtrace_logging_enabled
        end

        format.html { redirect_to @tire_listing, notice: 'Tire listing was successfully updated.' }
        #format.json { render json: @tire_listing }

        format.json { render :json => @tire_listing, :except => [:price], 
                :methods => [:short_description, :formatted_price, :photo1_thumbnail, 
                            :photo2_thumbnail, :photo3_thumbnail, :photo4_thumbnail,
                            :manufacturer_name, :model_name, :sizestr, :cl_title]}
      end
    end
  rescue Exception => e
    puts "Exception: #{e.message}"
    e.backtrace.each do |msg|
      puts msg
    end
    render :file => "public/422.html", :status => :internal_server_error
  end
end
