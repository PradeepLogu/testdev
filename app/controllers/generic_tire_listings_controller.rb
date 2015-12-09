include TireListingsHelper
include ApplicationHelper

class GenericTireListingsController < ApplicationController 
  before_filter :authenticate, except: [:update, :create]
  before_filter :is_correct_user,   only: [:edit, :update, :destroy]
  before_filter :has_posting_access, only: [:new, :create]

  def new
    if !signed_in?
      set_return_path(request.fullpath)      
      redirect_to signin_path, notice: "Please sign in."
      return
    end
        
    @tire_listing = GenericTireListing.new
    @tire_listing.tire_store_id = params[:tire_store_id]
    @tire_listing.quantity = 4
    @tire_listing.mounting_price = 0
    @wheeldiameters = TireSize.select('distinct wheeldiameter').order("wheeldiameter").map{|w| w.wheeldiameter.to_i}

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @tire_listing }
    end
  end

  def create
    @tire_listing = GenericTireListing.new(params[:generic_tire_listing])
    @tire_store = @tire_listing.tire_store
    params[:tire_sizes].each do |s|
      @tire_listing.add_tire_size_id(s)
    end

    respond_to do |format|
      if @tire_listing.save
        format.html { redirect_to @tire_store, notice: 'Generic listings were successfully created.' }
      else
        format.html { render action: "new" }
      end
    end
  end

  def update
    @tire_listing = GenericTireListing.find(params[:id])
    if !params[:tire_sizes].nil?
      @tire_listing.tire_sizes = {}
      params[:tire_sizes].each do |s|
        @tire_listing.add_tire_size_id(s)
      end
    end

    respond_to do |format|
      if @tire_listing.update_attributes(params[:generic_tire_listing])
        format.html { redirect_to @tire_listing.tire_store, notice: 'Generic listings were successfully updated.' }
      else
        puts "**** UPDATE FAILED ***"
      end
    end
  end

  def edit
    @tire_listing = GenericTireListing.find(params[:id])
    @tire_store = @tire_listing.tire_store
    @tire_listings = @tire_listing.tire_listings
    @wheeldiameters = TireSize.select('distinct wheeldiameter').order("wheeldiameter").map{|w| w.wheeldiameter.to_i}
  end

  def destroy
    @tire_listing = GenericTireListing.find(params[:id])
    @tire_store = @tire_listing.tire_store
    @tire_listing.destroy

    respond_to do |format|
      format.html { redirect_to tire_store_path(@tire_store), :alert => "Listing deleted." }
    end
  end

  def get_sizes_for_wheeldiameter
    @tire_sizes = TireSize.find(:all, :order => 'sizestr', :conditions => ["wheeldiameter = ?", params[:wheeldiameter]])
    @tire_listings = []
    if !params[:id].nil? && params[:id] != "0"
      @tire_listing = GenericTireListing.find(params[:id])
      if !@tire_listing.nil?
        @tire_listings = @tire_listing.tire_listings
      else
        @tire_listings = []
      end
    else
      @tire_listings = []
    end
    respond_to do |format|
      format.html { render :partial => 'tire_sizes' }
    end
  end

  private
    def is_correct_user
      if !super_user?
        @tire_listing = GenericTireListing.find(params[:id])
        if current_user.nil? || current_user.account_id != @tire_listing.tire_store.account_id
            redirect_to root_path, :alert => "You do not have access to that page." #{}" #{current_user.nil?} #{params[:id]} #{current_user.account_id}"
        end
      end
    end
end
