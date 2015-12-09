include ApplicationHelper
include TireStoresHelper

class TireStoresController < ApplicationController
  before_filter :authenticate
  before_filter :correct_ts_user,  :only => [:edit, :update, :destroy, :upgrade_to_premium]
  before_filter :load_storefront

  # GET /tire_store/transfer/1.json
  def transfer
    @tire_store = TireStore.find(params[:id]) unless @tire_store
    respond_to do |format|
      format.json { render :json => @tire_store, 
                      :except => [:id, :created_at, :updated_at, :latitude, :longitude] }
    end
  end

  def set_place_id
    @tire_store = TireStore.find(params[:tire_store_id])
    if @tire_store.nil? 
      flash[:info] = "Invalid request (could not find store)."
      redirect_to '/tire_stores'
      return
    elsif !@tire_store.google_place_id.blank?
      flash[:info] = "Invalid request (store's place already set)."
      redirect_to '/tire_stores'
      return
    else
      @tire_store.google_place_id = params[:place_id]
      @tire_store.save
      flash[:info] = "Store has been updated."
      redirect_to '/tire_stores'
      return
    end
  end

  def update_colors
    if params[:commit].include?('default')
      STOREFRONT_COLORS.each do |c|
        @tire_store.public_method((c[:key] + "=").to_sym).call(nil)
      end

      STOREFRONT_SIZES.each do |s|
        @tire_store.public_method((s[:key] + "=").to_sym).call(nil)
      end
    else
      params[:color].each do |p|
        if p[1] && p[1].size > 0
          begin
            @tire_store.public_method((p[0] + "=").to_sym).call(p[1])
            puts p[0]
          rescue
            puts "error setting #{p[0]}"
          end
        end
      end
      params[:size].each do |p|
        if p[1] && p[1].size > 0
          begin
            @tire_store.public_method((p[0] + "=").to_sym).call(p[1])
            puts p[0]
          rescue
            puts "error setting #{p[0]} to #{p[1]}"
          end
        end
      end
    end

    @tire_store.save

    respond_to do |format|
      format.js { render :nothing => true }
    end
  end

  def transfer_branding
    @tire_store = TireStore.find(params[:id]) unless @tire_store
    respond_to do |format|
      format.json { render :json => @tire_store, 
                      :only => :nothing,
                      :methods => [:logo_url] }
    end
  end
  
  
  def stores_by_location
    if !params.nil? && !params[:zipcode].blank?
      #params[:Location] = params[:zipcode]
      #params[:Radius] = "20"
      redirect_to :action => "index", :Location => params[:zipcode], :Radius => "20", :th_only => true
    elsif !params.nil? && !params[:city].blank? && !params[:state].blank?
      #params[:Location] = "#{params[:city]}, #{params[:state]}"
      #params[:Radius] = "20"
      redirect_to :action => "index", :Location => "#{params[:city]}, #{params[:state]}", :Radius => "20", :th_only => true
    end
  end
  

  # GET /tire_stores
  # GET /tire_stores.json
  def index
    #@tire_stores = TireStore.paginate(page: params[:page])
    
    
    ####@tire_stores = TireStore.search(params)
    ####@tire_stores = @tire_stores.paginate(page: params[:page]) unless @tire_stores.nil?
    
    begin
      if session[:showed_mobile_notice].blank? || session[:showed_mobile_notice].to_i < 10
        @show_mobile_notice = true
        session[:showed_mobile_notice] = session[:showed_mobile_notice].to_i + 1
      else
        @show_mobile_notice = false
      end
    rescue Exception => e 
      @show_mobile_notice = true 
    end

    @location = keywords = ""
    @radius = 0
    
    @location = params[:Location] if !params.nil?
    if @location.nil?
      if session[:location].blank?
        # let's try to set based on geoip
        begin
          loc = []
          i = 0
          while loc.empty? && i <= 5
            loc = Geocoder.search(request.remote_ip)[0]
            i += 1
          end
          if loc && !loc.city.blank?
            @location = loc.city + ', ' + loc.state
            session[:location] = @location
          end
        rescue
          puts "**** EXCEPTION"
        end
      else
        @location = session[:location]
      end
    end
    
    @radius = params[:Radius] if !params.nil?
    if @radius.nil?
      if session[:radius].blank?
        @radius = 10
      else
        @radius = session[:radius]
      end
    end
    
    keywords = params[:Keywords] if !params.nil?
    if keywords.nil?
      keywords = ""
    end

    @lc = LearningCenter.new
    @brand_seo = @lc.seo_tires_stores_search_results_page_posts
    
    # DG 7/22/15 - New functionality to change how the page looks when searching on a city and state.
    @page_mode = 'location'
    unless @location.blank?
      city_match = /\A([[:alpha:]](?:[[:alpha:]]|[-. ])+),\s+([A-Za-z]{2})\z/.match(@location.strip)
      if city_match
        @page_mode = 'city'
        @city = city_match[1].strip
        @state = city_match[2].upcase
        @location = "#{@city}, #{@state}"
      end
    end
    
    
    session[:location] = @location
    session[:radius] = @radius

    if !params.nil? && !params[:th_only].nil? && params[:th_only].downcase == "true"
      @tire_stores = TireStore.search(params)
      if @tire_stores.nil? || @tire_stores.size == 0
        @tire_stores = ScrapeTireStore.search_all_stores_by_location(@location, @radius, keywords, params[:page], 50)
      end
    else
      @tire_stores = ScrapeTireStore.search_all_stores_by_location(@location, @radius, keywords, params[:page], 50)
    end
    @tire_stores = @tire_stores.paginate(page: params[:page]) unless @tire_stores.nil?

    if !@tire_stores.nil? && @tire_stores.size == 1 && @tire_stores.first.th_customer
      redirect_to @tire_stores.first
    else
      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @tire_stores }
      end
    end
  end

  def stats
    #@tire_stores = TireStore.paginate(page: params[:page])
    params["IncludePrivate"] = "true"
    @tire_stores = TireStore.search(params)
    @tire_stores = @tire_stores.paginate(page: params[:page]) unless @tire_stores.nil?

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @tire_stores }
    end
  end

  def information
  end

  def info1
  end

  def info2
  end

  def info3
  end

  def info4
  end

  def ourtires    
    @ajax_mode = true
    get_search_params_and_store_defaults() if params[:auto_search] || params[:size_search] || params[:tire_size_id] || params[:tire_size_str]
    @tire_listings = @tire_store.find_tirelistings
    @tire_stores, @quantities, @tire_manufacturers, @categories, @sellers, @pictures, @conditions, @wheelsizes = create_mappings_turbo(@tire_listings)
  end

  def store
  end

  # GET /tire_stores/1/tire_listings.json
  def tire_listings
    @tire_store = TireStore.find(params[:id]) unless @tire_store
    @tire_listings = @tire_store.tire_listings
    respond_to do |format|
      format.json { render :json => @tire_listings, :except => [:price], :methods => [:formatted_price]}
    end
  end

  def reservations
    @tire_store = TireStore.find(params[:id]) unless @tire_store
    @reservations = @tire_store.reservations
    respond_to do |format|
      format.json { render :json => @reservations }
    end
  end

  def show_information
    @content = params[:content]
    respond_to do |format|
      format.js
    end
  end

  def create_mappings_turbo(listings)
    tire_stores = quantities = tire_manufacturers = categories = sellers = conditions = wheelsizes = []
    h = nil
    pictures = nil
    Rack::MiniProfiler.step("mapping all") do
      h = listings.map{|m| [[m.tire_manufacturer_id, m.tire_manufacturer_name], [m.quantity, m.quantity.to_s], [m.is_new, m.is_new? ? "New" : "Used"], [m.tire_category_id, m.tire_category.nil? ? "n/a" : m.tire_category.category_name], [m.wheelsize, m.wheelsize.to_s]]}.inject(Hash.new) {|h,x| h["manu"] = Hash.new(0) if h["manu"].nil?; h["manu"][x[0]]+=1; h["qty"] = Hash.new(0) if h["qty"].nil?; h["qty"][x[1]]+=1; h["condition"] = Hash.new(0) if h["condition"].nil?; h["condition"][x[2]]+=1; h["cat"] = Hash.new(0) if h["cat"].nil?; h["cat"][x[3]]+=1; h["wheelsize"] = Hash.new(0) if h["wheelsize"].nil?; h["wheelsize"][x[4]]+=1; h}
    end

    Rack::MiniProfiler.step("sorting all") do
      tire_stores = []
      quantities = h["qty"].sort_by{|k,v| k[1]} unless h["qty"].nil?
      tire_manufacturers = h["manu"].sort_by{|k,v| k[1]} unless h["manu"].nil?
      categories = h["cat"].sort_by{|k,v| k[1]} unless h["cat"].nil?
      sellers = []
      conditions = h["condition"].sort_by{|k,v| k[1]} unless h["condition"].nil?
      wheelsizes = h["wheelsize"].sort_by{|k,v| k[1]} unless h["wheelsize"].nil?
    end

    return tire_stores, quantities, tire_manufacturers, categories, sellers, pictures, conditions, wheelsizes  
  end

  def create_mappings(listings)
    tire_stores = quantities = tire_manufacturers = categories = sellers = conditions = wheelsizes = nil
    Rack::MiniProfiler.step("mapping tire_stores") do
      tire_stores = [] # listings.sort{|a,b| a.tire_store.visible_name.downcase <=> b.tire_store.visible_name.downcase}.map{|a| {:id => a.tire_store_id, :name => a.tire_store.visible_name}}.inject(Hash.new(0)) {|h,x| h[x]+=1;h}
    end
    Rack::MiniProfiler.step("mapping quantities") do
      quantities = listings.sort{|a,b| a.quantity <=> b.quantity}.map{|a| {:qty => a.quantity}}.inject(Hash.new(0)) {|h,x| h[x]+=1;h}
    end
    Rack::MiniProfiler.step("mapping tire_manufacturers") do    
      tire_manufacturers = listings.sort{|a,b| a.tire_manufacturer_name <=> b.tire_manufacturer_name}.map{|a| {:id => a.tire_manufacturer_id,
                                                              :name => a.tire_manufacturer_name}}.inject(Hash.new(0)) {|h,x| h[x]+=1;h}
    end
    Rack::MiniProfiler.step("mapping categories") do
      categories = listings.sort{|a,b| (a.tire_category and b.tire_category) ? a.tire_category.category_name <=> b.tire_category.category_name : (a.tire_category.nil? ? -1 : 1)}.map{|a| {:id => (a.tire_category ? a.tire_category.id : 0), :category => (a.tire_category ? a.tire_category.category_name : 'n/a')}}.inject(Hash.new(0)) {|h,x| h[x]+=1;h}
    end
    Rack::MiniProfiler.step("mapping sellers") do
      sellers = [] # listings.sort{|a,b| (a.tire_store.private_seller.to_s <=> b.tire_store.private_seller.to_s)}.map{|a| {:type => (a.tire_store.private_seller ? 'Private Sellers' : 'Storefronts'), :val => a.tire_store.private_seller}}.inject(Hash.new(0)) {|h,x| h[x]+=1;h}
    end
    # 1/11/13 ksi turn off because of performance issues
    ###pictures = listings.sort{|a,b| (a.photo1_thumbnail.nil?.to_s <=> b.photo1_thumbnail.nil?.to_s)}.map{|a| {:type => (a.photo1_thumbnail.nil? ? 'Listings without pictures' : 'Listings with pictures'), :val => a.photo1_thumbnail.nil?}}.inject(Hash.new(0)) {|h,x| h[x]+=1;h}
    Rack::MiniProfiler.step("mapping conditions") do    
      conditions = listings.sort{|a,b| (a.is_new.to_s <=> b.is_new.to_s)}.map{|a| {:type => (a.is_new ? 'New' : 'Used'), :val => a.is_new}}.inject(Hash.new(0)) {|h,x| h[x]+=1;h}
    end
    Rack::MiniProfiler.step("mapping wheelsizes") do    
      wheelsizes = listings.sort{|a,b| a.wheelsize <=> b.wheelsize}.map{|a| {:qty => a.wheelsize}}.inject(Hash.new(0)) {|h,x| h[x]+=1;h}
    end

    pictures = nil

    return tire_stores, quantities, tire_manufacturers, categories, sellers, pictures, conditions, wheelsizes  
  end
  
  # GET /tire_stores/1/promotions
  def promotions
    @tire_store = TireStore.find(params[:tire_store_id])
    @promotions = Promotion.unique_store_promotions(@tire_store, "all")
  end

  # GET /tire_stores/1
  # GET /tire_stores/1.json
  def show
    @search_mode = false      #true if we came here from a tire search
    @default_tab = 1
    # DG 7/16/15 - commented this out since it no longer applies
    #if (!session[:diameter].blank?)
    #  @default_tab = 2
    #else
    #  @default_tab = 1
    #end

    # we don't currently have an in-house review system...
    @th_reviews_available = false

    if !params[:inline_search].blank?
      if params[:inline_search].downcase == "true"
        session[:inline_search] = "true"
      else
        session[:inline_search] = nil 
      end
    end

    @diameters = TireSize.all_diameters
    @ratios = TireSize.all_ratios(session[:diameter])
    @wheeldiameters = TireSize.all_wheeldiameters(session[:ratio])

    Rack::MiniProfiler.step("load store and get params") do
      @tire_store = TireStore.find(params[:id]) unless @tire_store

      @tire_store.tire_size_id = params[:tire_size_id]

      impressionist(@tire_store)
      # DG 7/16/15 - commented this out since it no longer applies
      #get_search_params_and_store_defaults() # if params[:auto_search] || params[:size_search] || params[:tire_size_id]
      @reservations = @tire_store.reservations.paginate(page: params[:page])
      if params[:ajax_mode]
        @ajax_mode = params[:ajax_mode].to_s.to_bool
      else
        @ajax_mode = true
      end
    end

    # find nearby stores with reviews.
    ### @nearby_google_stores = TireStore.near([@tire_store.latitude, @tire_store.longitude], 20).limit(2).where("(EXIST(google_properties, 'google_place_id')=TRUE)'))")
    
    # DG 7/16/15 - For now, ignore any search params unless they came with a tire_search id.
    #We might use the id to provide a link back to the tire search results page.
    if !params[:tire_search].blank?
      #We've arrived on the tire store page from a tire search.
      #Rack::MiniProfiler.step("get tire search params") do
        @search_mode = true
        @tire_search_id = params[:tire_search].to_i
        get_search_params_and_query_string()
      #end
    end

    Rack::MiniProfiler.step("load tirelistings from db") do
      if params[:tab] && params[:tab].downcase == "used" && @tire_store.has_new_and_used?
        @tire_listings = @tire_store.used_tirelistings
      elsif params[:tab] && params[:tab].downcase == "new" && @tire_store.has_new_and_used?
        @tire_listings = @tire_store.new_tirelistings
      else
        @tire_listings = @tire_store.tire_listings
      end
    end

    # DG 7/16/15 - commented this out since it no longer applies
    #@refine_tire_search = TireSearch.new
    #@auto_manufacturers = AutoManufacturer.order("name")
    #@models = AutoModel.where(:auto_manufacturer_id => session[:manufacturer_id])
    #@years = AutoYear.where(:auto_model_id => session[:auto_model_id])
    #@options = AutoOption.where(:auto_year_id => session[:auto_year_id])    

    Rack::MiniProfiler.step("mapping stuff a") do
      @tire_stores, @quantities, @tire_manufacturers, @categories, @sellers, @pictures, @conditions, @wheelsizes = create_mappings_turbo(@tire_listings)
      #@tire_stores, @quantities, @tire_manufacturers, @categories, @sellers, @pictures, @conditions, @wheelsizes = create_mappings(@tire_listings)
      @can_edit = edit_access
    end
    Rack::MiniProfiler.step("mapping stuff b") do
      if @tire_store.storefront_assets.count > 0
        @photos = @tire_store.storefront_assets.map{ |x| {:img => x.image.to_s, :caption => x.caption, :url => x.url}}
      end
    end
    Rack::MiniProfiler.step("mapping stuff c") do
      if @tire_store.promotion_assets.count > 0
        @promotions = @tire_store.promotion_assets.map{ |x| {:img => x.image.to_s, :caption => x.caption, :url => x.url}}
      end
    end
    Rack::MiniProfiler.step("phone image") do
      if @tire_store.private_seller?
        t = TextToGIF.new()
        @phone_image = t.create_phone_gif_for_tire_store(@tire_store)
      end
    end

    Rack::MiniProfiler.step("loading search data (not anymore) and branding") do
      # DG 7/16/15 - commented this out since it no longer applies
      #load_default_search_data
      
      @branding = Branding.find_or_create_by_tire_store_id(@tire_store.id)

      if @branding.slogan.to_s.size > 0 && @branding.slogan_description.to_s.size > 0
        @slogan = @branding.slogan
        @slogan_description = @branding.slogan_description
      else
        @slogan = "Featured Tires"
        @slogan_description = "Here are some of the tires we feature at #{@tire_store.name}."
      end
    end

    @contact_seller = ContactSeller.new(:id => 1,
          :email => signed_in? ? current_user.email : '',
          :sender_name => signed_in? ? current_user.first_name + ' ' + current_user.last_name : "",
          :tire_store_id => @tire_store.id)    

    if @tire_store.private_seller?
      if signed_in? && (super_user? or current_user.account_id == @tire_store.account_id) then
        @submenu = Hash.new
        @submenu[:menu] = "Edit"
        @submenu[:items] = []
        @submenu[:items] << {href: "/tire_listings/new?tire_store_id=" + @tire_store.id.to_s, link: "Create a new listing"}
        @submenu[:items] << {href: "/tire_stores/#{@tire_store.id}/edit", link: "Edit Seller Information"}


        render :show_private
        return
      else
        redirect_to '/', :notice => "You do not have permission to view this page."  
        return
      end
    end

    if signed_in? && (super_user? or current_user.account_id == @tire_store.account_id) then
      @submenu = Hash.new
      @submenu[:menu] = "Create Listings"
      @submenu[:items] = []
      @submenu[:items] << {href: "/tire_listings/new?tire_store_id=" + @tire_store.id.to_s, link: "Create a new listing"}
      if !@tire_store.private_seller?
        @submenu[:items] << {href: "/new_multiple?tire_store_id=" + @tire_store.id.to_s, link: "Create Multiple New Tire Listings"}
        @submenu[:items] << {href: "/generic_tire_listings/new?tire_store_id=" + @tire_store.id.to_s, link: "Create Bulk Used Tire Listings"}
        @submenu[:items] << {href: edit_tire_store_path(@tire_store), link: "Edit Store Information"}
      end
    end
    
    # DG 8/6/15 - Setup appointment object for appointment modal
    @appointment = Appointment.new
    if !current_user.nil?
      @appointment.user_id = current_user.id if @appointment.user_id.blank?
      @appointment.buyer_name = current_user.name if @appointment.buyer_name.blank?
      @appointment.buyer_email = current_user.email if @appointment.buyer_email.blank?
      @appointment.buyer_phone = current_user.phone  if @appointment.buyer_phone.nil?
      @appointment.buyer_address = "" # current_user.address if @appointment.buyer_address.nil?
      @appointment.buyer_city = "" # current_user.city if @appointment.buyer_city.nil?
      @appointment.buyer_state = "" # current_user.state if @appointment.buyer_state.nil?
      @appointment.buyer_zip = "" # current_user.zipcode if @appointment.buyer_zip.nil?
    end
    if !params[:auto_options_id].blank?
      option = AutoOption.find(params[:auto_options_id])
      if option
        @appointment_auto = option.auto_year.modelyear + ' ' + 
                            option.auto_year.auto_model.auto_manufacturer.name + ' ' +
                            option.auto_year.auto_model.name + ' ' +
                            option.name
        @appointment.auto_option_id = option.id
        @appointment.auto_year_id = option.auto_year_id
        @appointment.auto_model_id = option.auto_year.auto_model_id
        @appointment.auto_manufacturer_id = option.auto_year.auto_model.auto_manufacturer_id
      end
    end
    @appointment.request_hour_primary = '12:00'     #default to 12 noon (if available)
    
    @appointments = {}
    @appt_counts = Appointment.store_appointments_by_day(@tire_store.id, Date.today, Date.today + 30.days)
    @primary_hours = @tire_store.hours_array_for_date(@appointment.request_date_primary)
    @secondary_hours = @tire_store.hours_array_for_date(@appointment.request_date_secondary)


    @ar_months = Date::MONTHNAMES.each_with_index.collect{|m, i| [m, i.to_s.rjust(2, '0')]}
    @ar_years = [*Date.today.year..Date.today.year + 8]    
    
    

    # 3/6/13 ksi Clean this mess up...
    if in_storefront?
      if @tire_search && @branding.template_number == 4
        ourtires()
        respond_to do |format|
          format.html {redirect_to params.merge!(:action => :ourtires) }
        end
      else  
        respond_to do |format|
          case @branding.template_number
            when 1
              format.html
            when 2
              format.html { render :show_storefront } #, :layout => 'storefront' }
            when 3
              format.html { render :show_storefront_slidetabs } #, :layout => 'storefront' }
            else
              format.html { render :show_storefront_traditional } #, :layout => 'storefront' }
          end
        end
      end
    else
      @turbo_mode = true # (params[:turbo].to_s > "")
      if @turbo_mode && !@ajax_mode
        Rack::MiniProfiler.step("JSONify") do
          @json = @tire_listings.to_json(:root => true,
                              #:except => [:price, :teaser, :description],
                              :only => [:id, :is_new, :tire_manufacturer_id, :treadlife, :quantity],
                              #:include => [:tire_manufacturer], 
                              :methods => [:cost_per_tire, :tire_category_id, :wheelsize]
                              )
        end
      else
        @json = ''
      end
      respond_to do |format|
        format.html # show.html.erb
        format.json { render json: @tire_store, :methods => [:sunday_open, :sunday_close, :monday_open, :monday_close, :tuesday_open, :tuesday_close, :wednesday_open, :wednesday_close, :thursday_open, :thursday_close, :friday_open, :friday_close, :saturday_open, :saturday_close, :closed_all_day_array, :open_all_day_array, :realtime_quote_distributors, :logo_url, :th_customer] }
      end
    end
  end

  # GET /tire_stores/new
  # GET /tire_stores/new.json
  def new
    if params[:account].nil? || params[:account] == ''
      if current_user.nil? || current_user.account.nil?
        redirect_to '/', :notice => "You do not have permission to create a storefront."  
      else
        redirect_to current_user.account, :notice => "You must create a store from an account page." 
      end
      return
    end

    @account = Account.find(params[:account])

    if !@account.tire_stores.first.nil? && @account.tire_stores.first.private_seller?
        redirect_to '/myTreadHunter', :notice => "Private sellers cannot create storefronts."  
        return
    end

    @tire_store = TireStore.new
    @tire_store.account_id = @account.id
    @tire_store.name = @account.name
    @tire_store.address1 = @account.address1
    @tire_store.address2 = @account.address2
    @tire_store.phone = @account.phone
    @tire_store.city = @account.city
    @tire_store.state = @account.state
    @tire_store.zipcode = @account.zipcode

    unless @account.nil?
      @tire_store.affiliate_id = @account.affiliate_id
      @tire_store.affiliate_time = @account.affiliate_time
      @tire_store.affiliate_referrer = @account.affiliate_referrer
    end

    @branding = Branding.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @tire_store }
    end
  end

  # GET /tire_stores/1/edit
  def edit
    if correct_ts_user
      @tire_store = TireStore.find(params[:id]) unless @tire_store
      if @tire_store.account.can_use_logo? && @tire_store.branding.nil?
        @branding = Branding.new
        @branding.tire_store_id = @tire_store.id
        @branding.save

        @tire_store.branding = @branding
      end
      @allow_craigslist_usage = false
      @branding = @tire_store.branding
      @tci = Distributor.find_by_distributor_name_and_city('Tire Centers, LLC', 'Norcross')
    else
      redirect_to root_path, :alert => "You do not have access to that page."
    end
  end

  # POST /tire_stores
  # POST /tire_stores.json
  def create
    @tire_store = TireStore.new(params[:tire_store].except(:account_id))
    
    @tire_store.account_id = params[:tire_store][:account_id]

    respond_to do |format|
      begin
        if has_create_access && @tire_store.save
          @branding = Branding.find_or_create_by_tire_store_id(@tire_store.id)
          if !@branding.nil? && params[:branding] && !params[:branding][:logo].blank?
            @branding.update_attributes(params[:branding])
            @branding.save
          end
          format.html { redirect_to @tire_store, notice: 'Tire store was successfully created.' }

          format.json { render json: @tire_store, status: :created, location: @tire_store }

        else
          puts '**** CREATE has_create_access failed or save failed'
          if params[:ajax_input]

          else
            format.html { render action: "new" }
            format.json { render json: @tire_store.errors, status: :unprocessable_entity }
          end
        end

        if params[:ajax_input]
          format.json { render json: "OK"}
        else
          redirect_to @tire_store, notice: 'Tire store was successfully created.'
          return
        end
      rescue Exception => e
        puts "Error creating tire store."
        puts "Exception: #{e.message}"
        e.backtrace.each do |msg|
          puts msg
        end
        format.html { redirect_to '/myTreadHunter', notice: 'Error creating tire store.'}
        return
      end
    end
  end

  def inventory_report_selector
    @tire_store = TireStore.find(params[:tire_store_id]) unless @tire_store

    @tire_sizes = TireSize.find(:all, :order => :sizestr)
    @tire_manufacturers = TireManufacturer.find(:all, :order => :name)
    @tire_models = []
    @tire_store_id = params[:tire_store_id]
    @report_mode = 'yes'
  end

  def inventory_report
    @tire_store = TireStore.find(params[:tire_store_id])

    puts "params_by_size: #{params[:report_by_size]} params_by_model: #{params[:report_by_model]}"
    if params[:report_by_size]
      @tire_size = TireSize.find(params[:tire_size])
      @title = "Inventory By Size (#{@tire_size.sizestr})"
      @tire_store.tire_size_id = @tire_size.id
      @tire_store.sort_order = SortOrder::SORT_BY_MANU_ASC
      @tire_listings = @tire_store.find_tirelistings
      render :layout => 'report'
    elsif params[:report_by_model] && params[:tire_model] && params[:tire_model].to_s.size > 0
      @tire_manufacturer = TireManufacturer.find(params[:tire_manufacturer_id])
      @title = "Inventory By Model (#{@tire_manufacturer_name} #{params[:tire_model]})"
      @tire_store.tire_model_name = params[:tire_model]
      @tire_store.sort_order = SortOrder::SORT_BY_SIZE_ASC
      @tire_listings = @tire_store.find_tirelistings
      render :layout => 'report'
    else
      flash[:alert] = "Please select a tire model and manufacturer."
      redirect_to :action => :inventory_report_selector, :tire_store_id => params[:tire_store_id]
    end
  end

  # PUT /tire_stores/1
  # PUT /tire_stores/1.json
  def update
    if correct_ts_user
      @tire_store = TireStore.find(params[:id]) unless @tire_store

      respond_to do |format|
        if @tire_store.update_attributes(params[:tire_store])
          ##puts "---->>>>> here <<<<<<------#{params[:closed_sunday]}"
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

          if !params[:online_payments].blank? && params[:online_payments] == "0"
            if !@tire_store.stripe_account_record.nil?
              # need to update to no stripe record....
              @tire_store.stripe_account_id = ""
            end
          elsif !params[:stripeAccountToken].blank?
            if @tire_store.stripe_account_record.nil?
              begin
                @tire_store.update_stripe_recipient_data_bank_account(params[:stripeBusinessName],
                      params[:stripeBusinessType], params[:stripeTaxID], params[:stripeAccountToken])
              rescue Exception => e
                puts "got an error in update_stripe_recipient_data_bank_account"
                flash[:alert] = e.to_s 
              end
            else
              # just need to update
              @tire_store.update_stripe_recipient_data_bank_account(params[:stripeBusinessName],
                      params[:stripeBusinessType], params[:stripeTaxID], params[:stripeAccountToken])
            end
          end

          @tire_store.save

          # now do promotions
          @promotions = Promotion.store_only_promotions(@tire_store, 'all').order('id')
          if @promotions.nil?
            @promotions = []
          end

          @deals = params[:deals]
          if @deals.nil?
            @deals = []
          end

          @promo_ids_to_delete = []

          if @promotions.length != @deals.length
            # if there are zero promotions, the @deals will have a blank deal first
            if (@promotions.length == 0 && @deals.length == 1 && @deals.first.blank?)
              # do nothing...there are no 'real' promotions
            else
              # there is a difference in size...so we need to update.

              # process the ones that match up
              (0..@promotions.length - 1).each do |i|
                if @deals[i].blank?
                  # delete the promotion
                  @promo_ids_to_delete << @promotions[i].id
                elsif @deals[i] != @promotions[i].promo_name
                  @promotions[i].update_attribute(:promo_name, @deals[i])
                end
              end

              # process the ones that are existing promotions but no longer 
              # in deals (they were deleted)
              (@deals.length..@promotions.length - 1).each do |i|
                @promo_ids_to_delete << @promotions[i].id
              end


              # process the ones that are in deals but not in 
              # existing promotions (they were added)
              (@promotions.length..@deals.length - 1).each do |i|
                p = Promotion.new 
                p.promo_name = @deals[i]
                p.promotion_type = "O"
                p.promo_level = "A"
                p.account_id = @tire_store.account_id
                p.add_tire_store_id_to_promotion(@tire_store.id)
                p.description = p.promo_name
                p.start_date = Date.today
                p.end_date = p.start_date + 1.year
                p.new_or_used = "N"
                p.save
              end
            end
          else
            # they are the same...update or delete as needed
            (0..@promotions.length - 1).each do |i|
              if @deals[i].blank?
                # delete the promotion
                @promo_ids_to_delete << @promotions[i].id
              elsif @deals[i] != @promotions[i].promo_name
                @promotions[i].update_attribute(:promo_name, @deals[i])
              end
            end
          end

          # delete the ones that need to go
          @promo_ids_to_delete.each do |id|
            Promotion.find(id).destroy
          end          

          if @tire_store.private_seller?
            store_type = 'Listing info'
          else
            store_type = 'Tire store'
          end
          
          begin
            @tire_store.branding.update_attributes(params[:branding])
          rescue
          end

          if params[:return_to_storefront].blank?
            format.html { redirect_to @tire_store, 
              notice: "#{store_type} was successfully updated." }
          else         
            format.html { redirect_to "/storefront/#{@tire_store.id}/edit", 
              notice: "Hours were successfully updated." }
          end

          format.json { head :no_content }
        else
          format.html { render action: "edit" }
          format.json { render json: @tire_store.errors, status: :unprocessable_entity }
        end
      end
    else
      redirect_to root_path, :alert => "You do not have access to that page."
    end
  end

  # DELETE /tire_stores/1
  # DELETE /tire_stores/1.json
  def destroy
    if correct_ts_user
      @tire_store = TireStore.find(params[:id]) unless @tire_store
      @tire_store.destroy

      respond_to do |format|
        ref_url = request.referer
        if ref_url.include?("?")
          ref_url += "&start_tab=my_stores"
        else
          ref_url += "?start_tab=my_stores"
        end
        format.html { redirect_to ref_url }
        format.json { head :no_content }
      end
    else
      redirect_to root_path, :alert => "You do not have access to that page."
    end      
  end

  def write_review
    @tire_store = TireStore.find_by_id(params[:tire_store_id])
    if @tire_store && !@tire_store.google_place_record.nil?
      @redirect_url = @tire_store.google_place_record.url + "/&review=1"
      redirect_to @redirect_url
      return
    else
      render :text => "This store does not have a Google Place record."
    end
  end

  def upgrade_to_premium
    if @tire_store.nil?
      @tire_store = current_user.tire_store 
    end

    if @tire_store.nil?
      redirect_to '/', notice: 'You do not have access to this page.'
      return
    end

    begin
      @tire_store.upgrade_to_premium
    rescue Exception => e
      redirect_to '/myTreadHunter', notice: e.to_s
      return
    end

    redirect_to '/myTreadHunter', notice: 'You have been upgraded to the premium plan!'
  end

  #def search
  #  @tire_stores = TireStore.search params[:search]
  #end
  private
    def load_default_search_data
      @manufacturers = AutoManufacturer.order("name")
      @models = AutoModel.where(:auto_manufacturer_id => session[:manufacturer_id])
      @years = AutoYear.where(:auto_model_id => session[:auto_model_id])
      @options = AutoOption.where(:auto_year_id => session[:auto_year_id])

      @diameters = TireSize.all_diameters
      @ratios = TireSize.all_ratios(session[:diameter])
      @wheeldiameters = TireSize.all_wheeldiameters(session[:ratio])

      nil
    end
    
    # DG 7/16/15 - New way of getting search params from a tire search page
    #The query string is used for ajax pagination calls.
    #Invalid parameters mean the search query will be ignored.
    def get_search_params_and_query_string
      if !params[:tire_model_id].blank?
        @tire_store.tire_model_id = params[:tire_model_id]
        @search_query = "tire_model_id=#{params[:tire_model_id].to_i}"
      else
        if !params[:auto_options_id].blank?
          option = AutoOption.find(params[:auto_options_id])
          @tire_store.tire_size_id = option.tire_size_id if option
        elsif !params[:width].blank? && !params[:ratio].blank? && !params[:wheeldiameter].blank?
          # check and make sure the size is valid
          ts = TireSize.find_by_sizestr("#{params[:width].to_i}/#{params[:ratio].to_i}R#{params[:wheeldiameter].to_i}")
          @tire_store.tire_size_id = ts.id if ts
        end
        
        if @tire_store.tire_size_id
          @search_query = "tire_size_id=#{@tire_store.tire_size_id}"
          
          #Don't include the manufacturer filter unless we have a valid size search going
          if !params[:tire_manufacturer_id].blank?
            @tire_store.tire_manufacturer_id_filter = params[:tire_manufacturer_id]
            @search_query += "&tire_manufacturer_id_filter=#{params[:tire_manufacturer_id].to_i}"
          end
        end
      end
    end

    # DG 7/16/15 - this method is no longer used
    def get_search_params_and_store_defaults
      # basic error checking
      @tire_search = get_tire_search_from_params

      size_search = false
      auto_search = false

      size_search = true if !params[:size_search].blank?
      auto_search = true if !params[:auto_search].blank?

      if !size_search && !auto_search
        # let's figure out which one it actually is
        if !params[:auto_manufacturer_id].blank? && !params[:auto_model_id].blank? &&
            !params[:auto_year_id].blank? && !params[:option_id].blank?
          auto_search = true
        elsif !params[:width].blank? && !params[:ratio].blank? && !params[:wheeldiameter].blank?
          size_search = true

          # check and make sure the size is valid
          ts = TireSize.find_by_sizestr("#{params[:width].to_i}/#{params[:ratio].to_i}R#{params[:wheeldiameter].to_i}")
          if !ts
            @tire_search = nil
            return
          end
        elsif params[:tire_size_id].blank? && params[:tire_size_str].blank?
          @tire_search = nil
          return
        end
      end

      begin
        if auto_search
          option = AutoOption.find(@tire_search.auto_options_id) unless @tire_search.auto_options_id.blank?

          @tire_search.tire_size_id = option.tire_size_id if option

          session[:manufacturer_id] = @tire_search.auto_manufacturer_id
          session[:auto_model_id] = @tire_search.auto_model_id
          session[:auto_year_id] = @tire_search.auto_year_id
          session[:option_id] = @tire_search.auto_options_id

          session[:diameter] = nil
          @tire_search.tire_size.diameter = nil
          session[:ratio] = nil
          @tire_search.tire_size.ratio = nil
          session[:wheeldiameter] = nil
          @tire_search.tire_size.wheeldiameter = nil
        else
          unless @tire_search.tire_size.nil?
            sizestr = sprintf('%g', @tire_search.tire_size.diameter.blank? ? 0 : @tire_search.tire_size.diameter) + 
                                '/' + sprintf('%g', @tire_search.tire_size.ratio.blank? ? 0 : @tire_search.tire_size.ratio) + 
                                'R' + sprintf('%g', @tire_search.tire_size.wheeldiameter.blank? ? 0 : @tire_search.tire_size.wheeldiameter) 
          end
          ts = TireSize.find_by_sizestr(sizestr)

          if ts
            @tire_search.tire_size_id = ts.id
          else
            @tire_search.tire_size_id = 0
          end

          session[:manufacturer_id] = nil
          @tire_search.auto_manufacturer_id = nil
          session[:auto_model_id] = nil
          @tire_search.auto_model_id = nil
          session[:auto_year_id] = nil
          @tire_search.auto_year_id = nil
          session[:option_id] = nil
          @tire_search.auto_options_id = nil
          session[:diameter] = @tire_search.tire_size.diameter unless @tire_search.tire_size.nil?
          session[:ratio] = @tire_search.tire_size.ratio unless @tire_search.tire_size.nil?
          session[:wheeldiameter] = @tire_search.tire_size.wheeldiameter unless @tire_search.tire_size.nil?
        end

        @tire_store.tire_size_id = @tire_search.tire_size_id

        session[:location] = @tire_search.locationstr unless @tire_search.locationstr.blank?
        session[:radius] = @tire_search.radius unless @tire_search.radius.blank?
        session[:quantity] = @tire_search.quantity.to_s 
      end
    end

    def get_tire_search_from_params
      @tire_search = TireSearch.new
      @tire_search.tire_size = TireSize.new

      begin
        if params[:tire_size_id]
          @tire_search.tire_size = TireSize.find(params[:tire_size_id])
        elsif params[:tire_size_str]
          puts "Searching for #{URI.unescape(params[:tire_size_str])}"
          @tire_search.tire_size = TireSize.find_by_sizestr(URI.unescape(params[:tire_size_str]))
        end
      rescue
        # not much I can do here
      end

      begin
        if params[:quantity] != nil
          @tire_search.quantity = params[:quantity]
        elsif !params["tire_search"].nil? && params["tire_search"]["quantity"] != nil
          @tire_search.quantity = params["tire_search"]["quantity"]
        else
            params.each do |param|
              @tire_search.quantity = param[1]["quantity"] if not param.nil? and not param[1]["quantity"].blank?
            end
        end
      rescue
        @tire_search.quantity = 0
      end

      begin
        if params[:auto_manufacturer_id] != nil
          @tire_search.auto_manufacturer_id = params[:auto_manufacturer_id]
        elsif !params["tire_search"].nil? && params["tire_search"]["auto_manufacturer_id"] != nil
          @tire_search.auto_manufacturer_id = params["tire_search"]["auto_manufacturer_id"]
        else
            params.each do |param|
              @tire_search.auto_manufacturer_id = param[1]["auto_manufacturer_id"] if not param.nil? and not param[1]["auto_manufacturer_id"].blank?
            end
        end
      rescue
        @tire_search.auto_manufacturer_id = 0
      end

      begin
        if params[:auto_model_id] != nil
          @tire_search.auto_model_id = params[:auto_model_id]
        elsif !params["tire_search"].nil? && params["tire_search"]["auto_model_id"] != nil
          @tire_search.auto_model_id = params["tire_search"]["auto_model_id"]
        else
            params.each do |param|
              @tire_search.auto_model_id = param[1]["auto_model_id"] if not param.nil? and not param[1]["auto_model_id"].blank?
            end
        end
      rescue
        @tire_search.auto_model_id = 0
      end

      begin
        if params[:auto_year_id] != nil
          @tire_search.auto_year_id = params[:auto_year_id]
        elsif !params["tire_search"].nil? && params["tire_search"]["auto_year_id"] != nil
          @tire_search.auto_year_id = params["tire_search"]["auto_year_id"]
        else
            params.each do |param|
              @tire_search.auto_year_id = param[1]["auto_year_id"] if not param.nil? and not param[1]["auto_year_id"].blank?
            end
        end
      rescue
        @tire_search.auto_year_id = 0
      end

      begin
        if params[:option_id] != nil
          @tire_search.auto_options_id = params[:option_id]
        elsif !params["tire_search"].nil? && params["tire_search"]["auto_options_id"] != nil
          @tire_search.auto_options_id = params["tire_search"]["auto_options_id"]
        else
            params.each do |param|
              @tire_search.auto_options_id = param[1]["option_id"] if not param.nil? and not param[1]["option_id"].blank?
            end
        end
      rescue
        @tire_search.auto_options_id = 0
      end

      begin
        if params[:locationstr] != nil
          @tire_search.locationstr = params[:locationstr]
        elsif !params["tire_search"].nil? && params["tire_search"]["locationstr"] != nil
          @tire_search.locationstr = params["tire_search"]["locationstr"]
        else
            params.each do |param|
              @tire_search.locationstr = param[1]["locationstr"] if not param.nil? and not param[1]["locationstr"].blank?
            end
        end
      rescue
        @tire_search.locationstr = ''
      end

      begin
        if params[:radius] != nil
          @tire_search.radius = params[:radius]
        elsif !params["tire_search"].nil? && params["tire_search"]["radius"] != nil
          @tire_search.radius = params["tire_search"]["radius"]
        else
            params.each do |param|
              @tire_search.radius = param[1]["radius"] if not param.nil? and not param[1]["radius"].blank?
            end
        end
      rescue
        @tire_search.radius = '20'
      end

      begin
        if params[:diameter] != nil
          @tire_search.tire_size.diameter = params[:diameter]
        elsif !params["tire_search"].nil? && params["tire_search"]["diameter"] != nil
          @tire_search.tire_size.diameter = params["tire_search"]["diameter"]
        else
            params.each do |param|
              @tire_search.tire_size.diameter = param[1]["diameter"] if not param.nil? and not param[1]["diameter"].blank?
            end
        end
      rescue
        @tire_search.tire_size.diameter = '0'
      end

      begin
        if params[:width] != nil
          puts "***** GOT a WIDTH #{params[:width]}"
          @tire_search.tire_size.diameter = params[:width]
        elsif !params["tire_search"].nil? && params["tire_search"]["width"] != nil
          @tire_search.tire_size.diameter = params["tire_search"]["width"]
        else
            params.each do |param|
              @tire_search.tire_size.diameter = param[1]["width"] if not param.nil? and not param[1]["width"].blank?
            end
        end
      rescue
        @tire_search.tire_size.diameter = '0'
      end

      begin
        if params[:wheeldiameter] != nil
          @tire_search.tire_size.wheeldiameter = params[:wheeldiameter]
        elsif !params["tire_search"].nil? && params["tire_search"]["wheeldiameter"] != nil
          @tire_search.tire_size.wheeldiameter = params["tire_search"]["wheeldiameter"]
        else
            params.each do |param|
              @tire_search.tire_size.wheeldiameter = param[1]["wheeldiameter"] if not param.nil? and not param[1]["wheeldiameter"].blank?
            end
        end
      rescue
        @tire_search.tire_size.wheeldiameter = '0'
      end

      begin
        if params[:ratio] != nil
          @tire_search.tire_size.ratio = params[:ratio]
        elsif !params["tire_search"].nil? && params["tire_search"]["ratio"] != nil
          @tire_search.tire_size.ratio = params["tire_search"]["ratio"]
        else
            params.each do |param|
              @tire_search.tire_size.ratio = param[1]["ratio"] if not param.nil? and not param[1]["ratio"].blank?
            end
        end
      rescue
        @tire_search.tire_size.ratio = '0'
      end

      begin
        if params[:low_price] != nil
          @tire_search.low_price = params[:low_price]
        elsif !params["tire_search"].nil? && params["tire_search"]["low_price"] != nil
          @tire_search.low_price = params["tire_search"]["low_price"]
        else
            params.each do |param|
              @tire_search.low_price = param[1]["low_price"] if not param.nil? and not param[1]["low_price"].blank?
            end
        end
      rescue
        @tire_search.low_price = ''
      end

      begin
        if params[:high_price] != nil
          @tire_search.high_price = params[:high_price]
        elsif !params["tire_search"].nil? && params["tire_search"]["high_price"] != nil
          @tire_search.high_price = params["tire_search"]["high_price"]
        else
            params.each do |param|
              @tire_search.high_price = param[1]["high_price"] if not param.nil? and not param[1]["high_price"].blank?
            end
        end
      rescue
        @tire_search.high_price = ''
      end

      @tire_search
    end
end
