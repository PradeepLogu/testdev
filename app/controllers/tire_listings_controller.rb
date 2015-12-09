require 'rest_client'
include ApplicationHelper

class TireListingsController < ApplicationController    
  impressionist :actions=>[:show]
  
  before_filter :authenticate, except: [:update, :show, :create, :create_multiple]
  before_filter :correct_user,   only: [:edit, :update, :destroy]
  before_filter :has_posting_access, only: [:new, :create, :new_multiple, :create_multiple]
  before_filter :is_super_user, only: [:index]
  #protect_from_forgery :except => :new, :except => :create
  # GET /tire_listings
  # GET /tire_listings.json

  include TireListingsHelper 

  def test_post
  end

   # GET /tire_listing/transfer/1.json
  def transfer_single
    @tire_listing = TireListing.find(params[:id])

    respond_to do |format|
      format.json { render :json => @tire_listing, 
          :except => [:id, :price, :created_at, :updated_at, 
                  :description, :teaser,
                  :photo1_content_type, :photo1_file_name, :photo1_file_size, :photo1_updated_at,
                  :photo2_content_type, :photo2_file_name, :photo2_file_size, :photo2_updated_at,
                  :photo3_content_type, :photo3_file_name, :photo3_file_size, :photo3_updated_at,
                  :photo4_content_type, :photo4_file_name, :photo4_file_size, :photo4_updated_at] }
    end
  end

  def transfer
    @tire_store = TireStore.find(params[:tire_store_id])

    respond_to do |format|
      format.json { render :json => @tire_store.tire_listings, 
                        :only => [:id],
                        :methods => [:manufacturer_name, :model_name, :sizestr, :formatted_price,
                                    :photo1_thumbnail, :photo2_thumbnail, 
                                    :photo3_thumbnail, :photo4_thumbnail]}
    end
  end
  
  def index
    @tire_listings = TireListing.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @tire_listings }
    end
  end

  def ajax
    bUnified = false

    if params[:id].start_with?('tl_')
      id = params[:id]
      id.slice!('tl_')
      @tire_listing = TireListing.find(id)
    elsif params[:id].start_with?('l_')
      id = params[:id]
      id.slice!('l_')
      @tire_listing = TireListing.find(id)
      bUnified = true
    else
      @tire_listing = TireListing.find(params[:id])
    end
    #respond_to do |format|
    #  format.html {render :ajax, :template => :new}
    #end
    if bUnified
      render :ajax_unified, :layout => false
    else
      render :ajax, :layout => false
    end
  end

  def new_multiple
    #@tire_store = TireStore.find(params[:tire_store_id])

    if !signed_in?
      set_return_path(request.fullpath)      
      redirect_to signin_path, notice: "Please sign in."
      return
    end

    @tire_sizes = TireSize.find(:all, :order => :sizestr)
    @tire_manufacturers = TireManufacturer.find(:all, :order => :name)
    @tire_models = []
    @tire_store_id = params[:tire_store_id]
  end

  def create_multiple
    # take each selected size and create listings
    tire_store = TireStore.find(params[:tire_store_id])

    if params[:create_by_model]
      puts "*** CREATE BY MODEL"
      @tire_models = TireModel.joins(:tire_size).where('tire_size_id in (?)', params[:tire_sizes]).find_all_by_tire_manufacturer_id_and_name(params[:tire_manufacturer_id], params[:tire_model])
      
      @tire_models.each do |model|
        # do we have an existing listing that is for this same set?
        tire_listing = TireListing.find_by_tire_store_id_and_tire_model_id_and_is_new(tire_store.id, model.id, true)
        if !tire_listing
          tire_listing = TireListing.new()
        end
        tire_listing.source = "multiple"
        tire_listing.tire_store_id = tire_store.id
        tire_listing.quantity = params["quantity_#{model.tire_size_id}"]
        tire_listing.tire_manufacturer_id = params[:tire_manufacturer_id]
        tire_listing.warranty_days = params[:warranty]
        tire_listing.includes_mounting = params[:inc_mounting]
        tire_listing.price = params["price_#{model.tire_size_id}"]
        tire_listing.tire_model_id = model.id
        tire_listing.tire_size_id = model.tire_size_id
        tire_listing.is_new = true
        tire_listing.save
      end
    else
      puts "*** CREATE BY SIZE"
      @tire_models = TireModel.where('id in (?)', params[:tire_models])
      
      @tire_models.each do |model|
        # do we have an existing listing that is for this same set?
        tire_listing = TireListing.find_by_tire_store_id_and_tire_model_id_and_is_new(tire_store.id, model.id, true)
        if !tire_listing
          tire_listing = TireListing.new()
        end
        tire_listing.source = "multiple"
        tire_listing.tire_store_id = tire_store.id
        tire_listing.quantity = params["quantity_#{model.id}"]
        tire_listing.tire_manufacturer_id = model.tire_manufacturer_id
        tire_listing.warranty_days = params[:warranty]
        tire_listing.includes_mounting = params[:inc_mounting]
        tire_listing.price = params["price_#{model.id}"]
        tire_listing.tire_model_id = model.id
        tire_listing.tire_size_id = model.tire_size_id
        tire_listing.is_new = true
        tire_listing.save
      end
    end

    redirect_to tire_store_path(params[:tire_store_id]), notice: 'Tire listings were successfully created.' 
  end

  def external_site
    @tire_listing = TireListing.find(params[:id])

    if @tire_listing.redirect_to && @tire_listing.redirect_to.is_valid_url?
      impressionist(@tire_listing.tire_store)
      redirect_to @tire_listing.redirect_to
    else
      # invalid or missing URL - back to show
      redirect_to tire_store_path(params[:tire_store_id]), notice: 'Unable to show more details about this listing.'
    end
  end

  # GET /tire_listings/1
  # GET /tire_listings/1.json
  def show
    @tire_listing = TireListing.find(params[:id])

    # 10/13/15 ksi - this is no longer a valid page, we're
    # going to redirect to the store listings page.
    redirect_to "/tire-stores/#{@tire_listing.tire_store_id}?tire_size_id=#{@tire_listing.tire_size_id}"
    return

    if super_user? or (signed_in? && current_user.account_id == @tire_listing.tire_store.account_id)
      @submenu = Hash.new
      @submenu[:menu] = "Add or Edit Listings"
      @submenu[:items] = []
      @submenu[:items] << {href: edit_tire_listing_path(@tire_listing), link: "Edit this listing"}
      @submenu[:items] << {href: "/tire_listings/new?tire_store_id=" + @tire_listing.tire_store.id.to_s, link: "Create a new listing"}
      if !@tire_listing.tire_store.private_seller?
        @submenu[:items] << {href: "/new_multiple?tire_store_id=" + @tire_listing.tire_store.id.to_s, link: "Create multiple new tire listings"}
      end
    end

    impressionist(@tire_listing.tire_store)

    @contact_seller = ContactSeller.new(:id => 1,
              :email => signed_in? ? current_user.email : '',
              :sender_name => signed_in? ? current_user.first_name + ' ' + current_user.last_name : "",
              :tire_store_id => @tire_listing.tire_store_id)

    @reservation = Reservation.new(:user_id => signed_in? ? current_user.id : 0,
                              :tire_listing_id => @tire_listing.id,
                              :buyer_email => signed_in? ? current_user.email : '',
                              :seller_email => @tire_listing.tire_store.contact_email,
                              :name => signed_in? ? current_user.first_name + ' ' + 
                                          current_user.last_name : "",
                              :phone => signed_in? ? current_user.phone : '',
                              :address => session[:street_address],
                              :city => session[:city],
                              :state => session[:state],
                              :zip => session[:zip],
                              :phone => session[:phone], 
                              :quantity => (@tire_listing.is_new ? 1 : @tire_listing.quantity),
                              :tire_manufacturer_id => @tire_listing.tire_manufacturer_id, 
                              :tire_model_id => @tire_listing.tire_model_id, 
                              :tire_size_id => @tire_listing.tire_size_id)
    if params[:errors]
      params[:errors].each do |e|
        @reservation.errors.add(e[0], e[1][0])
      end
    end

    @similarStoreListings = TireListing.where('tire_store_id = ? and tire_size_id = ? and id <> ?',
      @tire_listing.tire_store_id, @tire_listing.tire_size_id, @tire_listing.id).limit(10)

    @otherStoreListings = TireListing.where('tire_store_id = ? and id <> ?',
      @tire_listing.tire_store_id, @tire_listing.id).limit(10) 

    @otherStoreSimilarListings = TireListing.near(@tire_listing).where('tire_store_id <> ? and tire_size_id = ?',
      @tire_listing.tire_store_id, @tire_listing.tire_size_id).limit(10)

    
    @promotions = []
    @tire_listing.eligible_promotions.each do |p|
      @promotions << Promotion.find_all_by_uuid(p.uuid, :order => :id)    
    end

    if @tire_listing.tire_store.has_branding? && @tire_listing.tire_store.branding.listing_html
      respond_to do |format|
        format.html { render :show_branding, :layout => 'branding' }
        format.json { render :json => @tire_listing, :except => [:price], :methods => [:formatted_price, :photo1_thumbnail, :photo2_thumbnail, :photo3_thumbnail, :photo4_thumbnail]}
      end
    else
      # we're going to use Bing Maps API to calculate the 'real' distance and directions
      # from the supplied geocoded location to the store.
      begin
        routesURL = 'http://dev.virtualearth.net/REST/v1/Routes/Driving' +
            '?wp.1=' + session[:mylatitude].to_s + ',' + session[:mylongitude].to_s +
            '&wp.2=' + @tire_listing.tire_store.latitude.to_s + ',' + @tire_listing.tire_store.longitude.to_s + 
            '&key=ArW5u_MZDCbLaSabVyXCaOxN18AZnpdQawOJYvUlz33z9Uq9GYWz-a4ycWvk_6F2&distanceUnit=mile'
        #puts routesURL
        response = RestClient.get routesURL
        parsedJSON = JSON.parse(response)

        @drivingDistance = parsedJSON["resourceSets"][0]["resources"][0]["routeLegs"][0]["travelDistance"]
      rescue Exception=>e
        # we couldn't get directions...no biggie
        puts "****ERROR*****"
        puts e.to_s
      end

      if @tire_listing.tire_store.private_seller?
        t = TextToGIF.new()
        @phone_image = t.create_phone_gif_for_tire_store(@tire_listing.tire_store)
      end
      respond_to do |format|
        format.html # show.html.erb
        #format.json { render json: @tire_listing, :except => [:price] }
        format.json { render :json => @tire_listing, :except => [:price], :methods => [:formatted_price, :photo1_thumbnail, :photo2_thumbnail, :photo3_thumbnail, :photo4_thumbnail]}
      end
    end
  end

  # GET /tire_listings/new
  # GET /tire_listings/new.json
  def new
    @tire_store = TireStore.find(params[:tire_store_id])

    @tire_listing = TireListing.new
    @tire_manufacturers = [] # TireManufacturer.all
    @tire_models = []
    # need to find VALID sizes @tire_sizes = TireSize.order("sizestr")
    @tire_sizes = TireSize.valid_sizes
    @tire_listing.tire_store_id = @tire_store.id
    @tire_listing.willing_to_ship = @tire_store.willing_to_ship
    @tire_listing.price = 0

    @template = @tire_listing.tire_store.cl_template

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @tire_listing }
    end
  end

  # GET /tire_listings/1/edit
  def edit
    @tire_listing = TireListing.find(params[:id])

    if !@tire_listing.nil? && @tire_listing.is_generic?
      redirect_to edit_generic_tire_listing_path(@tire_listing.generic_tire_listing)
    end

    @tire_sizes = TireSize.valid_sizes
    @temp_models = TireModel.find_all_by_tire_size_id(@tire_listing.tire_size_id).map(&:tire_manufacturer_id)
    @tire_manufacturers = TireManufacturer.where("id in (?)", @temp_models).order(:name)
    @tire_models = TireModel.where("tire_manufacturer_id = ? and tire_size_id = ?", 
                    @tire_listing.tire_manufacturer_id, @tire_listing.tire_size_id).select('distinct name, id').order("name")
    puts "**** FOUND #{@tire_models.count.to_s} models and #{@tire_manufacturers.count.to_s} manus"
  end

  def defaultDescription
    @tire_listing = TireListing.new(params[:tire_listing])
    get_tire_listing_helper_params(@tire_listing, params)

    respond_to do |format|
      format.html {render json: @tire_listing.to_json(:only => [], :methods => [:default_description, :default_teaser])}
      format.json {render json: @tire_listing.to_json(:only => [], :methods => [:default_description, :default_teaser])}
    end
  end

  # POST /tire_listings
  # POST /tire_listings.json
  def create
    @tire_listing = TireListing.new(params[:tire_listing])
    get_tire_listing_helper_params(@tire_listing, params)
    #@tire_manufacturers = TireManufacturer.all

    if @tire_listing.is_new == true
      if params && params[:tire_store] && 
          params[:tire_store][:change_default_willing_to_ship] && 
          params[:tire_store][:change_default_willing_to_ship] == "true" &&
          @tire_listing.willing_to_ship > 0
        @tire_listing.tire_store.update_attribute(:willing_to_ship, @tire_listing.willing_to_ship)
      end
    end

    respond_to do |format|
      if @tire_listing.save
        @tire_listing.compress_photo_array
        format.html { redirect_to @tire_listing, notice: 'Tire listing was successfully created.' }
        format.json { render json: @tire_listing, status: :created, location: @tire_listing }
      else
        @tire_sizes = TireSize.valid_sizes
        @tire_manufacturers = []
        @tire_models = []

        @template = @tire_listing.tire_store.cl_template

        format.html { render action: "new" }
        format.json { render json: @tire_listing.errors, status: :unprocessable_entity }
      end
    end
  end

  def get_tire_listing_helper_params(tire_listing, params)
    tire_listing.tire_size_id = params[:tire_size_id] if params[:tire_size_id]
    tire_listing.tire_manufacturer_id = params[:tire_manufacturer_id] if params[:tire_manufacturer_id]
    tire_listing.tire_model_id = params[:tire_model_id] if params[:tire_model_id]
  end

  # PUT /tire_listings/1
  # PUT /tire_listings/1.json
  def update
    @tire_listing = TireListing.find(params[:id])
    get_tire_listing_helper_params(@tire_listing, params)

    respond_to do |format|
      if @tire_listing.update_attributes(params[:tire_listing])
        @tire_listing.compress_photo_array
        #if params[:tire_listing][:description]
        #  a = params[:tire_listing][:description].gsub(/\n/, '<br />')
        #  @tire_listing.update_attribute(:description, a)
        #end
        #if params[:tire_listing][:teaser]
        #  a = params[:tire_listing][:teaser].gsub(/\n/, '<br />')
        #  @tire_listing.update_attribute(:teaser, a)
        #end
        format.html { redirect_to @tire_listing, notice: 'Tire listing was successfully updated.' }
        format.json { render json: @tire_listing }
      else
        format.html { render action: "edit" }
        format.json { render json: @tire_listing.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tire_listings/1
  # DELETE /tire_listings/1.json
  def destroy
    @tire_listing = TireListing.find(params[:id])
    @tire_store = @tire_listing.tire_store
    @tire_listing.destroy

    respond_to do |format|
      format.html { redirect_to tire_store_path(@tire_store), :alert => "Listing deleted." }
      format.json { head :no_content }
    end
  end

  def tire_manufacturer_selected
    # user changed manufacturer, reload models and clear out sizes
    @tire_manufacturer = TireManufacturer.find(params[:tire_manufacturer_id])
    @tire_models = TireModel.where("tire_manufacturer_id = ? and tire_size_id = ?", params[:tire_manufacturer_id], params[:tire_size_id]).select('distinct name, id').order("name")

    render :update do |page|
      page.replace_html 'tire_model_info', :partial => 'layouts/tire_model_info', :locals => {:tire_model => nil, :hidden => true}
      page.replace_html 'tire_models',  :partial => 'layouts/tire_models',  :object => @tire_models,     :locals => {:f => @tire_listing}
    end
  end

  def tire_size_selected
    # user has selected a tire size, let's blank out model and find valid manufacturers
    @temp_models = TireModel.find_all_by_tire_size_id(params[:tire_size_id]).map(&:tire_manufacturer_id)
    @tire_manufacturers = TireManufacturer.where("id in (?)", @temp_models)
    @tire_models = TireModel.where('id = 0')
    render :update do |page|
      page.replace_html 'tire_model_info', :partial => 'layouts/tire_model_info', :locals => {:tire_model => nil, :hidden => true}
      page.replace_html 'tire_manufacturers', :partial => 'layouts/tire_manufacturers', :object => @tire_manufacturers, :locals => {:f => @tire_listing}
      page.replace_html 'tire_models', :partial => 'layouts/tire_models', :object => @tire_models, :locals => {:f => @tire_listing}
    end
  end

  def tire_model_selected
    # user has selected everything we need to find a tire model
    @model = TireModel.find(params[:tire_model_id])
    if @model.nil?
      # we couldn't find a record for this size/manu/model
      render :update do |page|
        page.replace_html 'tire_model_info', :partial => 'layouts/tire_model_info', :locals => {:tire_model => nil, :hidden => true}
        page.replace_html 'treadlife', :partial => 'layouts/treadlife', 
                :locals => {:disabled => false, :message => ''} 
      end
    else
      # we need to put the tire_information modal dialog up, but we also need
      # to enable or disable the treadlife field
      render :update do |page|
        page.replace_html 'tire_model_info', :partial => 'layouts/tire_model_info', :locals => {:tire_model => @model, :hidden => true}
        page.replace_html 'treadlife', :partial => 'layouts/treadlife', 
                :locals => {:disabled => true, :message => 'Orig tread: ' + @model.tread_depth.to_s + '/32'} 
      end
    end
  end
end
