class AppointmentsController < ApplicationController
  #before_filter :is_super_user, only: [:show, :edit, :index]

  def new
    # id is required to deal with form
    @appointment = Appointment.new
    @tire_store = TireStore.find(params[:tire_store_id])
    @tire_listing = TireListing.find_by_id(params[:tire_listing_id])
    @appointment.tire_listing_id = params[:tire_listing_id]

    if !params[:order_id].blank?
      @order = Order.find_by_id(params[:order_id])
      if @order.nil?
        redirect_to @tire_listing, notice: "Unable to find that order"
      else
        if params[:order_uuid] != @order.uuid 
          redirect_to '/', notice: 'Invalid order link'
        end
      end
    end

    initialize_data
    initialize_appointments_for_buyer
  end

  def create
    begin
      request_date_primary = (params[:appointment]["request_date_primary(1i)"] + '-' + params[:appointment]["request_date_primary(2i)"] + '-' + params[:appointment]["request_date_primary(3i)"]).to_date
      if params[:appointment]["request_date_secondary(1i)"].blank?
        request_date_secondary = request_date_primary
      else
        request_date_secondary = (params[:appointment]["request_date_secondary(1i)"] + '-' + params[:appointment]["request_date_secondary(2i)"] + '-' + params[:appointment]["request_date_secondary(3i)"]).to_date        
      end
    rescue Exception => e
      request_date_primary = Date.today + 1.day
      request_date_secondary = Date.today + 1.day
    end

    @tire_store = TireStore.find_by_id(params[:appointment][:tire_store_id])
    @tire_listing = TireListing.find_by_id(params[:appointment][:tire_listing_id])
    @tire_listing = TireListing.new if @tire_listing.nil?

    @appointment = Appointment.new

    initialize_data

    @appointment.buyer_name = params[:appointment][:buyer_name]
    @appointment.buyer_email = params[:appointment][:buyer_email]
    @appointment.buyer_phone = params[:appointment][:buyer_phone]
    @appointment.buyer_address = params[:appointment][:buyer_address] ||= "not required"
    @appointment.buyer_city = params[:appointment][:buyer_city] ||= "not required"
    @appointment.buyer_state = params[:appointment][:buyer_state] ||= "GA"
    @appointment.buyer_zip = params[:appointment][:buyer_zip] ||= "99999"
    @appointment.tire_store_id = @tire_store.id
    @appointment.tire_listing_id = @tire_listing.id
    @appointment.price = @tire_listing.price
    @appointment.quantity = params[:appointment][:quantity]
    @appointment.set_mileage(params[:appointment][:vehicle_mileage])
    @appointment.request_date_primary = request_date_primary
    @appointment.request_date_secondary = request_date_secondary
    @appointment.request_hour_primary = params[:appointment][:request_hour_primary]
    @appointment.request_hour_primary = params[:request_hour_primary] if @appointment.request_hour_primary.nil?
    if params[:appointment][:request_hour_secondary].blank?
      @appointment.request_hour_secondary = @appointment.request_hour_primary
    else
      @appointment.request_hour_secondary = params[:appointment][:request_hour_secondary]
      @appointment.request_hour_secondary = params[:request_hour_secondary] if @appointment.request_hour_secondary.nil?
    end

    @appointment.preferred_contact_path = params[:appointment][:preferred_contact_path]
    @appointment.notes = params[:appointment][:notes]

    @appointment.auto_manufacturer_id = params[:auto_manufacturer_id]
    @appointment.auto_model_id = params[:auto_model_id]
    @appointment.auto_year_id = params[:auto_year_id]
    @appointment.auto_option_id = params[:option_id]

    session[:manufacturer_id] = @appointment.auto_manufacturer_id
    session[:auto_model_id] = @appointment.auto_model_id
    session[:auto_year_id] = @appointment.auto_year_id
    session[:option_id] = @appointment.auto_option_id

    if params[:services]
      params[:services].each do |svc|
        @appointment.add_service_id_to_appointment(svc)
      end
    end

    #@success = false
    #begin
    #  @success = @appointment.save!
    #rescue ActiveRecord::RecordInvalid => invalid
    #  puts "*** INVALID ***"
    #  invalid.record.errors.each do |s|
    #    puts s.to_s 
    #  end
    #  puts "----->" + invalid.to_s
    #  puts invalid.record.errors.size
    #end

    #begin
    #  @appointment.save
    #rescue Exception => e
    #  puts "FAILED SAVE: #{e.to_s}"
    #end

    if @appointment.save
      if !params[:appointment][:order_id].blank?
        @order = Order.find_by_id(params[:appointment][:order_id])
        if @order
          @order.appointment_id = @appointment.id 
          @order.save

          # if we have already successfully transferred funds to the seller but not sent
          # an email yet, we'll send it now.  The Successful Transfer email has appointment
          # information, so we'd prefer to just send it once, and preferably after an
          # appointment has been made.
          if !@order.stripe_transfer_token.blank?
            BillingMailer.delay.successful_funds_transfer(@order)
          end

          # if we have already charged the credit card but not sent an email yet, we'll
          # send it now.  The Successfully Charged email has appointment
          # information, so it's best to send it after the appointment has been made.
          if !@order.stripe_charge_token.blank?
            BillingMailer.delay.successfully_billed_buyer(@order)
            BillingMailer.delay.successfully_billed_seller(@order)
          end
        end
      end

      Notification.create_pending_appointment_confirmations(@appointment.tire_listing.tire_store_id)      

      if !@appointment.new_record?
        respond_to do |format|
          format.html { redirect_to @tire_store, notice: 'Your appointment request has been sent, you should receive communication from the store soon.' }
        end
        return
      elsif !@tire_store.nil?
        respond_to do |format|
          format.html { redirect_to @tire_store, notice: 'Your appointment request has been sent, you should receive communication from the store soon.' }
        end
        return
      else
        respond_to do |format|
          format.html { redirect_to '/', notice: 'Your appointment request has been sent, you should receive communication from the store soon.' }
        end
        return
      end
    else
      puts "**** ERROR SAVING *** #{@appointment.valid?} #{@appointment.errors.size}"
      @appointment.errors.each do |e|
        puts "Error 1: " + e.to_s
      end

      initialize_data
      initialize_appointments_for_buyer
      render action: "new"
    end
  end

  def ajax_order_details
    # TODO: confirm permissions
    @order = Order.find_by_id(params[:order_id])
    if @order 
      respond_to do |format|
        format.html { render :partial => 'layouts/order_details_modal', :locals => {:@order => @order} }
      end
    else
      render :file => "public/422.html", :status => :unauthorized
    end
  end

  def confirm_primary
    # TODO: confirm permissions
    @appt = Appointment.find_by_id(params[:appt_id])
    if @appt ### && VALIDATE_PERMISSIONS
      @appt.confirm_primary_appointment
      respond_to do |format|
        format.json { render json: @appt.to_json(:methods => [:order_price, :title, :start, :end, :color, :order_price, :order_id, :formatted_buyer_phone, :formatted_price, :confirmed_time, :primary_request_time, :secondary_request_time, :vehicle_name, :services_list]) }
      end
    else
      render :file => "public/422.html", :status => :unauthorized
    end    
  end

  def confirm_secondary
    # TODO: confirm permissions
    @appt = Appointment.find_by_id(params[:appt_id])
    if @appt ### && VALIDATE_PERMISSIONS
      @appt.confirm_secondary_appointment
      respond_to do |format|
        format.json { render json: @appt.to_json(:methods => [:order_price, :title, :start, :end, :color, :order_price, :order_id, :formatted_buyer_phone, :formatted_price, :confirmed_time, :primary_request_time, :secondary_request_time, :vehicle_name, :services_list]) }
      end
    else
      render :file => "public/422.html", :status => :unauthorized
    end    
  end  

  def deny_appointment
    # TODO: confirm permissions
    @appt = Appointment.find_by_id(params[:appt_id])
    if @appt ### && VALIDATE_PERMISSIONS
      @appt.reject_appointment
      respond_to do |format|
        format.json { render json: @appt.to_json(:methods => [:order_price, :title, :start, :end, :color, :order_price, :order_id, :formatted_buyer_phone, :formatted_price, :confirmed_time, :primary_request_time, :secondary_request_time, :vehicle_name, :services_list]) }
      end
    else
      render :file => "public/422.html", :status => :unauthorized
    end    
  end  

  def ajax_appointment
    # TODO: confirm permissions
    @appt = Appointment.find_by_id(params[:appt_id])
    if @appt ### && VALIDATE
      respond_to do |format|
        format.json { render json: @appt.to_json(:methods => [:order_price, :order_id, :formatted_buyer_phone, :formatted_price, :confirmed_time, :primary_request_time, :secondary_request_time, :vehicle_name, :services_list]) }
      end
    else
      render :file => "public/422.html", :status => :unauthorized
    end
  end

  def html_appointments_by_day
    # TODO: confirm permissions
    @day = params[:appt_date]
    if !signed_in?
      @appointments = []
    else
      @account = current_user.account
      @appointments = []

      @account.tire_stores.each do |t|
        if params[:tire_store_id].blank? || params[:tire_store_id].downcase == "all" ||
          params[:tire_store_id] == t.id.to_s 
          @appointments |= t.appointments_with_range(Date.parse(@day), 0)
        end
      end

      @appointments = @appointments.sort{|a, b| "#{a.order.nil?.to_s}#{a.id}" <=> "#{b.order.nil?.to_s}#{b.id}"}
    end
    if @appointments ### && VALIDATE
      respond_to do |format|
        format.html { render :partial => 'layouts/my_treadhunter/day_appointments_list', :locals => {:@appointments => @appointments} }
      end
    else
      render :file => "public/422.html", :status => :unauthorized
    end
  end

  def initialize_data
    if !@order.nil?
      @appointment.user_id = @order.user_id if @appointment.user_id.blank?
      @appointment.buyer_name = @order.buyer_name if @appointment.buyer_name.blank?
      @appointment.buyer_email = @order.buyer_email if @appointment.buyer_email.blank?
      @appointment.buyer_phone = @order.buyer_phone  if @appointment.buyer_phone.blank?
      @appointment.buyer_address = @order.buyer_address1 if @appointment.buyer_address.blank?
      @appointment.buyer_city = @order.buyer_city if @appointment.buyer_city.blank?
      @appointment.buyer_state = @order.buyer_state if @appointment.buyer_state.blank?
      @appointment.buyer_zip = @order.buyer_zip if @appointment.buyer_zip.blank?
    end

    if !current_user.nil?
      @appointment.user_id = current_user.id if @appointment.user_id.blank?
      @appointment.buyer_name = current_user.name if @appointment.buyer_name.blank?
      @appointment.buyer_email = current_user.email if @appointment.buyer_email.blank?
      @appointment.buyer_phone = current_user.phone  if @appointment.buyer_phone.nil?
    end

    @appointment.auto_manufacturer_id = session[:manufacturer_id] if @appointment.auto_manufacturer_id.nil?
    @appointment.auto_model_id = session[:auto_model_id] if @appointment.auto_model_id.nil?
    @appointment.auto_year_id = session[:auto_year_id] if @appointment.auto_year_id.nil?
    @appointment.auto_option_id = session[:option_id] if @appointment.auto_option_id.nil?

    @manufacturers = AutoManufacturer.order("name")
    @models = AutoModel.where(:auto_manufacturer_id => @appointment.auto_manufacturer_id)
    @years = AutoYear.where(:auto_model_id => @appointment.auto_model_id)
    @options = AutoOption.where(:auto_year_id => @appointment.auto_year_id)   

    @services = Service.all
  end

  def initialize_appointments_for_buyer
    @appointments = {}

    @appt_counts = Appointment.store_appointments_by_day(@tire_store.id, Date.today, Date.today + 30.days)

    @primary_hours = @tire_store.hours_array_for_date(@appointment.request_date_primary)
    @secondary_hours = @tire_store.hours_array_for_date(@appointment.request_date_secondary)

    @appt_counts.each do |ar|
      cnt = ar[1].to_i
      if cnt < 4
        @appointments[ar[0]] = "Beige,Looks good"
      elsif cnt < 6
        @appointments[ar[0]] = "Gold,Filling up"
      elsif cnt < 8
        @appointments[ar[0]] = "LightPink,Busy"
      else
        @appointments[ar[0]] = "Red,Book now!"
      end
    end
  end

  def confirm_appointments
    if !signed_in?
      set_return_path(request.fullpath)      
      redirect_to signin_path, notice: "Please sign in."
    elsif current_user.is_tirebuyer? && !super_user?
      redirect_to '/', notice: "You do not have access to that page."
    else
      @account = current_user.account

      if !@account
        redirect_to '/accounts/new', notice: "You do not have an account set up."
      end
      @tire_store = TireStore.find_by_id(params[:tire_store_id])

      #@appointments = @tire_store.appointments.to_a.map(&:serializable_hash)
      @appointments = @tire_store.appointments.to_json(:only => [:id, :buyer_name], :methods => [:order_price, :title, :start, :end, :color])
    end
  end  
end