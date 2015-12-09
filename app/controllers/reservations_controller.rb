include ReservationsHelper

class ReservationsController < ApplicationController
  before_filter :correct_user, only: [:edit, :update, :show, :destroy] 
  before_filter :is_superuser, only: [:index]
  impressionist :actions=>[:create]

  # GET /reservations
  # GET /reservations.json
  def index
    @reservations = Reservation.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @reservations }
    end
  end

  # GET /reservations/1
  # GET /reservations/1.json
  def show
    @reservation = Reservation.find(params[:id])

    if false # need to figure out if json mode or not...
      if !super_user? or !signed_in? or (@reservation.user_id != current_user.id and 
                                        @reservation.tire_listing.tire_store.account_id != current_user.account_id)
        redirect_to root_path, :alert => "You do not have access to that page."
        return
      end
    end

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @reservation }
    end
  end

  # GET /reservations/new
  # GET /reservations/new.json
  def new
    @reservation = Reservation.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @reservation }
    end
  end

  # GET /reservations/1/edit
  def edit
    @reservation = Reservation.find(params[:id])
  end

  # POST /reservations
  # POST /reservations.json
  def create
    @reservation = Reservation.new(params[:reservation])
    @reservation.expiration_date = 2.days.from_now

    @tire_listing = TireListing.find(@reservation.tire_listing_id)

    session[:street_address] = @reservation.address
    session[:city] = @reservation.city
    session[:state] = @reservation.state
    session[:zip] = @reservation.zip
    session[:phone] = @reservation.phone

    @reservation.price = @tire_listing.price
    @reservation.tire_manufacturer_id = @tire_listing.tire_manufacturer_id
    @reservation.tire_model_id = @tire_listing.tire_model_id
    @reservation.tire_size_id = @tire_listing.tire_size_id

    respond_to do |format|
      if !simple_captcha_valid?
        format.html { redirect_to tire_listing_path(@tire_listing, 
                        :reservation => "true",
                        :errors => @reservation.errors.to_hash), 
                      notice: 'Error creating reservation - invalid CAPTCHA value.' }
        format.json { render json: @reservation.errors, status: :unprocessable_entity }
        
      elsif @reservation.save
        impressionist(@tire_listing.tire_store)
        format.html { redirect_to @tire_listing, 
          notice: 'Tire has been reserved for you.  You should receive an email shortly; the seller will also receive an email with your contact information.  This reservation will be cancelled in 48 hours.' }
        format.json { render json: @reservation, status: :created, location: @reservation }
      else
        puts @reservation.errors

        #format.html { render action: "new" }
        format.html { redirect_to tire_listing_path(@tire_listing, 
                        :reservation => "true",
                        :errors => @reservation.errors.to_hash), 
                      notice: 'Error creating reservation.' }
        format.json { render json: @reservation.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /reservations/1
  # PUT /reservations/1.json
  def update
    @reservation = Reservation.find(params[:id])

    respond_to do |format|
      if @reservation.update_attributes(params[:reservation])
        format.html { redirect_to @reservation, notice: 'Reservation was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @reservation.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /reservations/1
  # DELETE /reservations/1.json
  def destroy
    @reservation = Reservation.find(params[:id])

    # send cancellation emails...
    if signed_in?
      if super_user?
        @reservation.cancel_reservation(CancelParty::SYSTEM)
      else
        if @reservation.buyer_email.downcase == current_user.email.downcase
          @reservation.cancel_reservation(CancelParty::BUYER)
        else
          @reservation.cancel_reservation(CancelParty::SELLER)
        end
      end
    else
      @reservation.cancel_reservation(CancelParty::USER)
    end
    
    @reservation.destroy

    respond_to do |format|
      format.html { redirect_to :root, notice: 'Reservation was successfully deleted.' }
      format.json { head :no_content }
    end
  end
end
