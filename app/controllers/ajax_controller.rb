include ApplicationHelper
include TireStoresHelper

#include ActionView::Helpers
#include Gritter::Helpers

class AjaxController < ApplicationController
  # GET /tire_searches
  # GET /tire_searches.json

  def register_for_newsletter
    @email_address = params[:newsletter_email].to_s
    if @email_address.include?("please enter")
      @email_address = ""
    end

    if @email_address.blank?
      respond_to do |format|
        format.html { render :partial => 'layouts/homepage/get_treadhunter_news', 
                              :locals => {:action => "get_registration",
                                          :message => "Please enter an email address."} }
      end
    elsif @email_address.is_valid_email?
      success, message = MailChimp.SubscribeToNewsletter(@email_address, request.remote_ip)

      if success
        session[:registered_newsletter] = @email_address
        respond_to do |format|
          format.html { render :partial => 'layouts/homepage/get_treadhunter_news', 
                                :locals => {:action => "register_success"} }
        end
      else
        respond_to do |format|
          format.html { render :partial => 'layouts/homepage/get_treadhunter_news', 
                                :locals => {:action => "get_registration",
                                            :message => message}}

        end
      end
    else
      respond_to do |format|
        format.html { render :partial => 'layouts/homepage/get_treadhunter_news', 
                              :locals => {:action => "get_registration",
                                          :message => "Invalid email - #{@email_address}"} }
      end
    end
  end

  def update_auto_models
    # updates models based on manufacturer selected
    @manufacturer = AutoManufacturer.find(params[:manufacturer_id])
    @models = @manufacturer.auto_models.order(:name)
    @years = AutoYear.where('id = 0')
    @options = AutoOption.where('id = 0')
    
    respond_to do |format|
      format.html { render :partial => 'layouts/ajax_auto_models', :locals => {:c => params[:c]} }
    end
  end

  def update_auto_models_visfire
    # updates models based on manufacturer selected
    @manufacturer = AutoManufacturer.find(params[:manufacturer_id])
    @models = @manufacturer.auto_models.order(:name)
    @years = AutoYear.where('id = 0')
    @options = AutoOption.where('id = 0')
    
    respond_to do |format|
      format.html { render :partial => 'layouts/ajax_auto_models_visfire', :locals => {:c => params[:c]} }
    end
  end
  
  def update_auto_years
    # updates years based on manufacturer and model selected
    if params[:model_id] && params[:model_id] != '0'
      @model = AutoModel.find(params[:model_id])
      @years = @model.auto_years.order(:modelyear)
      @options = [] # AutoOption.where('id = 0')
    else
      @model = []
      @years = []
      @options = []
    end
    
    respond_to do |format|
      format.html { render :partial => 'layouts/ajax_auto_years', :locals => {:c => params[:c]} }
    end
  end
  
  def update_auto_years_visfire
    # updates years based on manufacturer and model selected
    if params[:model_id] && params[:model_id] != '0'
      @model = AutoModel.find(params[:model_id])
      @years = @model.auto_years.order("modelyear DESC")
      @options = [] # AutoOption.where('id = 0')
    else
      @model = []
      @years = []
      @options = []
    end
    
    respond_to do |format|
      format.html { render :partial => 'layouts/ajax_auto_years_visfire', :locals => {:c => params[:c]} }
    end
  end

  def update_auto_options
    # updates options based on manufacturer, model, and year selected
    if params[:auto_year_id] && params[:auto_year_id] != '0'
      @year = AutoYear.find(params[:auto_year_id])
      @options = @year.auto_options
    else
      @year = []
      @options = []
    end
    
    respond_to do |format|
      format.html { render :partial => 'layouts/ajax_auto_options', :locals => {:c => params[:c]} }
    end
  end

  def update_auto_options_visfire
    # updates options based on manufacturer, model, and year selected
    if params[:auto_year_id] && params[:auto_year_id] != '0'
      @year = AutoYear.find(params[:auto_year_id])
      @options = @year.auto_options
    else
      @year = []
      @options = []
    end
    
    respond_to do |format|
      format.html { render :partial => 'layouts/ajax_auto_options_visfire', :locals => {:c => params[:c]} }
    end
  end

  def update_tire_ratios
    # updates the aspect ratio and wheel diameter drop lists when diameter (section width) changes
    @ratios = TireSize.all_ratios(params[:width])
    
    respond_to do |format|
      format.html { render :partial => 'layouts/ajax_tire_ratios' }
    end
  end

  def update_tire_ratios_visfire
    # updates the aspect ratio and wheel diameter drop lists when diameter (section width) changes
    @ratios = TireSize.all_ratios(params[:width])
    
    respond_to do |format|
      format.html { render :partial => 'layouts/ajax_tire_ratios_visfire' }
    end
  end

  def update_tire_wheeldiameters
    # updates the aspect ratio and wheel diameter drop lists when diameter (section width) changes
    @wheeldiameters = TireSize.all_wheeldiameters(params[:ratio])
    
    respond_to do |format|
      format.html { render :partial => 'layouts/ajax_tire_wheeldiameters' }
    end
  end

  def update_tire_wheeldiameters_visfire
    # updates the aspect ratio and wheel diameter drop lists when diameter (section width) changes
    @wheeldiameters = TireSize.all_wheeldiameters(params[:ratio])
    
    respond_to do |format|
      format.html { render :partial => 'layouts/ajax_tire_wheeldiameters_visfire' }
    end
  end

  def update_tire_manufacturers
    # user has selected a tire size, let's blank out model and find valid manufacturers
    @temp_models = TireModel.find_all_by_tire_size_id(params[:tire_size_id]).map(&:tire_manufacturer_id)
    @tire_manufacturers = TireManufacturer.where("id in (?)", @temp_models).order(:name)
    @tire_models = []
    
    respond_to do |format|
      format.html { render :partial => 'layouts/ajax_tire_manufacturers' }
    end
  end

  def update_tire_manufacturers_visfire
    # user has selected a tire size, let's blank out model and find valid manufacturers
    @temp_models = TireModel.find_all_by_tire_size_id(params[:tire_size_id]).map(&:tire_manufacturer_id)
    @tire_manufacturers = TireManufacturer.where("id in (?)", @temp_models).order(:name)
    @tire_models = []
    
    respond_to do |format|
      format.html { render :partial => 'layouts/ajax_tire_manufacturers_visfire' }
    end
  end

  def update_tire_models
    # user changed manufacturer, reload models and clear out sizes
    #@tire_manufacturer = TireManufacturer.find(params[:tire_manufacturer_id])
    @tire_models = TireModel.where("tire_manufacturer_id = ? and tire_size_id = ?", params[:tire_manufacturer_id], params[:tire_size_id]).order("name")

    respond_to do |format|
      format.html { render :partial => 'layouts/ajax_tire_models' }
    end
  end

  def update_tire_models_visfire
    # user changed manufacturer, reload models and clear out sizes
    #@tire_manufacturer = TireManufacturer.find(params[:tire_manufacturer_id])
    @tire_models = TireModel.where("tire_manufacturer_id = ? and tire_size_id = ?", params[:tire_manufacturer_id], params[:tire_size_id]).order("name")

    respond_to do |format|
      format.html { render :partial => 'layouts/ajax_tire_models_visfire' }
    end
  end

  def update_tire_models_no_size
    # user changed manufacturer
    @tire_models = TireModel.where("tire_manufacturer_id = ?", params[:tire_manufacturer_id]).select('distinct name').order("name")
    @tire_store_id = params[:tire_store_id]
    
    respond_to do |format|
      format.html { render :partial => 'layouts/ajax_tire_models_no_size', 
                          :locals => {:@tire_store_id => @tire_store_id} }
    end
  end

  def update_tire_model_checkboxes
    # user changed manufacturer
    @tire_models = TireModel.where("tire_manufacturer_id = ?", params[:tire_manufacturer_id]).select('distinct name').order("name")

    respond_to do |format|
      format.html { render :partial => 'layouts/tire_model_checkboxes' }
    end
  end

  def get_models_for_tire_size
    @default_manu = []
    @tire_store = TireStore.find(params[:tire_store_id])

    if params[:tire_size_id]
      @tire_size = TireSize.find(params[:tire_size_id])
      if @tire_size
        @tire_models = @tire_size.tire_models.sort {|a,b| a.tire_manufacturer.name <=> b.tire_manufacturer.name}
        @tire_manufacturers = @tire_size.tire_manufacturers.uniq.sort{|a,b| a.name <=> b.name}
        #tmp = ['BF Goodrich', 'Goodyear', 'Michelin']
        tmp = @tire_store.manufacturer_names_carried
        @default_manu = (@tire_manufacturers.select { |i| tmp.include?(i.name) }).map(&:id)
      else
        @tire_models = []
      end
    else
      @tire_models = []
    end

    @tire_listings = @tire_store.new_tirelistings

    if params[:report_mode] != 'yes'
      respond_to do |format|
        format.html { render :partial => 'layouts/tire_model_table' }
      end
    #else
    #  redirect_to :action => :inventory_report, :controller => :tire_stores,
    #            :tire_store_id => 5, :bob => 3
    end
  end

  def get_sizes_for_model
    if params[:tire_manufacturer_id] && params[:tire_model_name]
      @tire_models = TireModel.joins(:tire_size).find_all_by_tire_manufacturer_id_and_name(params[:tire_manufacturer_id], params[:tire_model_name], :order => :sizestr)
    else
      @tire_models = []
    end

    @tire_store = TireStore.find(params[:tire_store_id])
    @tire_listings = @tire_store.new_tirelistings

    if params[:report_mode] != 'yes'
      respond_to do |format|
        format.html { render :partial => 'layouts/tire_size_table',
                              :locals => {:@tire_listings => @tire_listings} }
      end
    #else
    #  redirect_to :action => :inventory_report, :controller => :tire_stores,
    #            :tire_store_id => 5, :bob => 3
    end
  end

  def validate_size_str
    arFormatted_str = /(\d{3}).*(\d{2}).*(\d{2})/.match(params[:tire_size_str])
    if arFormatted_str
      puts arFormatted_str
      @ts = TireSize.find_by_sizestr("#{arFormatted_str[1]}/#{arFormatted_str[2]}R#{arFormatted_str[3]}")

      respond_to do |format|
        format.html {render json: @ts.to_json(:only => [:id, :sizestr])}
      end
    else
      render :nothing => true, :status => :fail
    end
  end

  def load_tiresearch_records
    @tire_search = TireSearch.find(params[:id])

    params.select{|key| key.include?('_filter')}.each do |k, v|
      if @tire_search.respond_to?(k)
        @tire_search.send("#{k}=", v)
      end
    end

    set_listing_sort_order(@tire_search, SortOrder::SORT_BY_DISTANCE_ASC)

    #@listings = @tire_search.paginated_tirelistings_page(params[:page]) 
    @listings = ConsolidatedTireListing.insert_consolidated_listings(@tire_search.paginated_tirelistings_page(params[:page]))
    respond_to do |format|
      if visfire_storemode
        format.html { render :partial => 'layouts/paginated_listings_visfire',
                              :locals => {:@listings => @listings, :page_no => params[:page]} }
      else
        format.html { render :partial => 'layouts/paginated_listings',
                              :page_no => params[:page],
                              :locals => {:@listings => @listings} }
      end
    end
  end
  
  def load_tiresearch_stores
    @tire_search = TireSearch.find(params[:id])

    set_listing_sort_order(@tire_search, SortOrder::SORT_BY_DISTANCE_ASC)

    @stores = @tire_search.paginated_tirestores_page(params[:page])
    respond_to do |format|
      format.html { render :partial => 'layouts/paginated_store_results', # 'layouts/paginated_model_listings',
                            :locals => {:@stores => @stores,
                                        :@search_query => @tire_search.url_params('', true) + "&tire_search=#{@tire_search.id}",
                                        :page_no => params[:page], :offset => ((params[:page].to_i - 1) * 50)} }
    end
  end

  def load_storelisting_records
    @tire_store = TireStore.find(params[:id])

    [:tire_size_id, :tire_model_id].each do |k|
      if !params[k].blank?
        @tire_store.send("#{k.to_s}=", params[k])
      end
    end

    params.select{|key| key.include?('_filter')}.each do |k, v|
      if @tire_store.respond_to?(k)
        @tire_store.send("#{k}=", v)
      end
    end

    set_listing_sort_order(@tire_store, SortOrder::SORT_BY_UPDATED_DESC)

    @listings = @tire_store.paginated_tirelistings(params[:page])
    respond_to do |format|
      if visfire_storemode
        format.html { render :partial => 'layouts/paginated_listings_visfire',
                              :locals => {:@listings => @listings, :page_no => params[:page]} }
      else
        format.html { render :partial => 'layouts/paginated_listings',
                              :locals => {:@listings => @listings} }
      end
    end
  end
  
  def load_manufacturer_models
    @brand = TireManufacturer.find(params[:id])
    
    params.select{|key| key.include?('_filter')}.each do |k, v|
      if @brand.respond_to?(k)
        @brand.send("#{k}=", v)
      end
    end

    set_listing_sort_order(@brand, 0)

    @models = @brand.paginated_model_listings(params[:page])
    @tire_search = TireSearch.new
    
    respond_to do |format|
      format.html { render :partial => 'layouts/paginated_model_listings',
                            :locals => {:@models => @models, :page_no => params[:page],
                                        :@tire_search => @tire_search} }
    end
  end
  
  # DG - Consolidated sort logic to here.
  def set_listing_sort_order(search_object, default_val)
    if params[:sort]
      sort_order = params[:sort].downcase
      case sort_order
        when "manu"
          search_object.sort_order = SortOrder::SORT_BY_MANU_ASC
        when "manud"
          search_object.sort_order = SortOrder::SORT_BY_MANU_DESC
        when "size"
          search_object.sort_order = SortOrder::SORT_BY_SIZE_ASC
        when "sized"
          search_object.sort_order = SortOrder::SORT_BY_SIZE_DESC
        when "upd"
          search_object.sort_order = SortOrder::SORT_BY_UPDATED_ASC
        when "updd"
          search_object.sort_order = SortOrder::SORT_BY_UPDATED_DESC
        when "qty"
          search_object.sort_order = SortOrder::SORT_BY_QTY_ASC
        when "type"
          search_object.sort_order = SortOrder::SORT_BY_TYPE_ASC
        when "treadd"
          search_object.sort_order = SortOrder::SORT_BY_TREADLIFE_DESC
        when "distance"
          search_object.sort_order = SortOrder::SORT_BY_DISTANCE_ASC
        when "cost"
          search_object.sort_order = SortOrder::SORT_BY_COST_PER_TIRE_ASC
        when "costd"
          search_object.sort_order = SortOrder::SORT_BY_COST_PER_TIRE_DESC
        when "name"
          search_object.sort_order = SortOrder::SORT_BY_MODEL_NAME_ASC
        when "named"
          search_object.sort_order = SortOrder::SORT_BY_MODEL_NAME_DESC
        when "store"
          search_object.sort_order = SortOrder::SORT_BY_STORE_NAME_ASC
        when "stored"
          search_object.sort_order = SortOrder::SORT_BY_STORE_NAME_DESC
        else
          search_object.sort_order = default_val
      end
    else
      search_object.sort_order = default_val
    end
  end

  def build_store_placeholder
    if params[:tire_listing_ids] 
      @tire_listings = TireListing.find(:all, :conditions => ["id IN (?)", params[:tire_listing_ids].split(',')])
    else
      @tire_listings = []
    end

    #@tire_manufacturers = []
    @tire_manufacturers = @tire_listings.sort{|a,b| a.tire_manufacturer_name <=> b.tire_manufacturer_name}.map{|a| {:id => a.tire_manufacturer_id, :name => a.tire_manufacturer_name}}.inject(Hash.new(0)) {|h,x| h[x]+=1;h}
    @min_price = @tire_listings.min_by(&:price).price
    @max_price = @tire_listings.max_by(&:price).price
    @distance = params[:distance]

    respond_to do |format|
      format.html { render :partial => 'layouts/store_placeholder' }
    end
  end

  def update_hours_for_store
    @tire_store = TireStore.find(params[:tire_store_id])
    @date_selected = "#{params[:selected_year]}/#{params[:selected_month]}/#{params[:selected_day]}"
    @date = Date.parse(@date_selected)
    @hours = @tire_store.hours_array_for_date(@date)
    @primary = params[:secondary].blank?
    
    respond_to do |format|
      format.html { render :partial => 'layouts/ajax_store_hours' }
    end
  end

  def new_notifications
    if !params[:since].blank?
      dt_since = DateTime.parse(params[:since])

      # TODO: use the since
      if !current_user.nil?
        @notifications = Notification.user_notifications_since(current_user.id, dt_since)
        if !current_user.account.nil?
          @notifications = @notifications | Notification.public_account_notifications_since(current_user.account_id, dt_since)
        end
        if !current_user.account.nil? && current_user.is_admin?
          @notifications = @notifications | Notification.admin_account_notifications_since(current_user.account_id, dt_since)
        end
        if super_user?
          @notifications = @notifications | Notification.super_user_notifications_since(dt_since)
        end
      else
        @notifications = []
      end

      @notifications.each do |n|
        n.viewed()
      end

      respond_to do |format|
        format.html { render :partial => 'layouts/ajax_new_notifications', 
                                :locals => {:@notifications => @notifications} }
      end
    else
      @notifications = []
      respond_to do |format|
        format.html { render :partial => 'layouts/ajax_new_notifications', 
                                :locals => {:@notifications => @notifications} }
      end
    end
  end

  def appointments_table
    if !signed_in?
      @appointments = []
    else
      @account = current_user.account
      @appointments = []

      @account.tire_stores.each do |t|
        if params[:tire_store_id].blank? || params[:tire_store_id].downcase == "all" ||
          params[:tire_store_id] == t.id.to_s 
          @appointments |= t.appointments
        end
      end
    end

    @appt_json = @appointments.to_json(:only => [:id, :buyer_name], :methods => [:order_price, :title, :calendar_line1, :calendar_sort, :start, :end, :color, :tire_store_name])

    respond_to do |format|
      format.html { render :partial => 'layouts/my_treadhunter/appointments_table',
                        :locals => {:@appointments => @appointments,
                                    :@show_store => (!params[:tire_store_id].nil? &&
                                          params[:tire_store_id].downcase == "all")} }
    end
  end

  def listings_table
    if !signed_in?
      @listings = []
    else
      @account = current_user.account
      @listings = []

      if params[:tire_store_id].blank? || params[:tire_store_id].downcase == "all"
        #@listings = @account.top_tire_listings
        @listings = @account.tire_listings
      else
        @account.tire_stores.each do |t|
          if params[:tire_store_id].blank? || params[:tire_store_id].downcase == "all" ||
            params[:tire_store_id] == t.id.to_s 
            #@listings |= t.top_tire_listings
            @listings |= t.tire_listings
          end
        end
      end
    end

    respond_to do |format|
      format.html { render :partial => 'layouts/my_treadhunter/listings_table',
                        :locals => {:@listings => @listings,
                                    :@show_store => (!params[:tire_store_id].nil? && 
                                      params[:tire_store_id].downcase == "all")} }
    end
  end

  def promotions_table
    if !signed_in?
      arPromotions = []
    else
      @account = current_user.account
      arPromotions = []

      @account.tire_stores.each do |t|
        if params[:tire_store_id].blank? || params[:tire_store_id].downcase == "all" ||
          params[:tire_store_id] == t.id.to_s 
          arPromotions |= Promotion.store_promotions(t, "all").map(&:id)
        end
      end
    end

    @promotions = Promotion.where(:id => arPromotions)

    respond_to do |format|
      format.html { render :partial => 'layouts/my_treadhunter/promotions_table',
                            :locals => {:@promotions => @promotions} }
    end
  end

  def searches_table
    if !signed_in?
      arSearches = []
    else
      @account = current_user.account
      arSearches = []

      @account.tire_stores.each do |t|
        if params[:tire_store_id].blank? || params[:tire_store_id].downcase == "all" ||
          params[:tire_store_id] == t.id.to_s 
          arSearches |= TireSearch.near([t.latitude, t.longitude], 50).where("created_at >= '" + (Time.now - 7.days).to_s + "'").map(&:id)
        end
      end
    end

    @searches = TireSearch.select("sizestr, tire_size_id, count(tire_size_id)").where(:id => arSearches).group("sizestr, tire_size_id").joins("inner join tire_sizes on tire_sizes.id = tire_size_id").order("count(tire_size_id) DESC")

    respond_to do |format|
      format.html { render :partial => 'layouts/my_treadhunter/searches_table',
                            :locals => {:@searches => @searches} }
    end
  end

  def stores_table
    if !signed_in?
      set_return_path(request.fullpath)      
      redirect_to signin_path, notice: "Please sign in."
    elsif current_user.is_tirebuyer? && !super_user?
      redirect_to '/', notice: "You do not have access to that page."
    else
      @account = current_user.account
      if !@account && !super_user?
        redirect_to '/accounts/new', notice: "You do not have an account set up."
      end
    end

    respond_to do |format|
      format.html { render :partial => 'layouts/my_treadhunter/stores_table',
                          :locals => {:@account => @account} }
    end
  end

  def users_table
    if !signed_in?
      @users = []
    else
      @users = current_user.account.users
    end

    respond_to do |format|
      format.html { render :partial => 'layouts/my_treadhunter/users_table',
                          :locals => {:@users => @users} }
    end
  end
  
  def edit_store
    if !signed_in?
      set_return_path(request.fullpath)
      redirect_to signin_path, notice: "Please sign in."
    elsif current_user.is_tirebuyer? && !super_user?
      redirect_to '/', notice: "You do not have access to that page."
    else
      @account = current_user.account
      if !@account && !super_user?
        redirect_to '/accounts/new', notice: "You do not have an account set up."
      end
    end

    @account = current_user.account
    
    if params[:tire_store_id].blank? || params[:tire_store_id] == 'new'
      @tire_store = TireStore.new
      @tire_store.account_id = @account.id
      @tire_store.affiliate_id = @account.affiliate_id
      @tire_store.affiliate_time = @account.affiliate_time
      @tire_store.affiliate_referrer = @account.affiliate_referrer
      @tire_store.contact_email = current_user.email
      
      @branding = Branding.new
      @tire_store.branding = @branding
    else
      @tire_store = nil
      @account.tire_stores.each do |t|
        if params[:tire_store_id] == t.id.to_s
          @tire_store = t
        end
      end
      
      if @tire_store
        if @account.can_use_logo? && @tire_store.branding.nil?
          @branding = Branding.new
          @branding.tire_store_id = @tire_store.id
          @branding.save
          @tire_store.branding = @branding
        end
        @branding = @tire_store.branding
      end
    end

    @promotions = Promotion.store_only_promotions(@tire_store, 'all').order('id')
    if @promotions.nil? || @promotions.length == 0
      @promotions << Promotion.new # empty one
    end
        
    respond_to do |format|
      format.html { render :partial => 'layouts/my_treadhunter/edit_store',
                          :locals => {:@account => @account, :@tire_store => @tire_store} }
    end
  end
  

  def ajax_promotion_details
    @promotions = []

    @promo = Promotion.find_by_id(params[:promotion_id])

    @promotions << Promotion.find_all_by_uuid(@promo.uuid, :order => :id)    

    if @promo
      respond_to do |format|
        format.html { render :partial => 'promotions/promotion', :locals => {:@promotions => @promotions} }
      end
    else
      render :file => "public/422.html", :status => :unauthorized
    end
  end

  def get_lat_lon_from_zip(zip)
    if !zip.blank?
      begin
        url = "http://api.geonames.org/postalCodeLookupJSON?postalcode=#{zip}&country=US&username=treadhunter"
        result = JSON.parse(open(url).read)
        if result
          @lat = result["postalcodes"][0]["lat"]
          @lng = result["postalcodes"][0]["lng"]
          return @lat, @lng
        else
          return nil, nil 
        end
      rescue
        return nil, nil
      end
    else
      return nil, nil
    end
  end

  def get_store_from_phone_and_zip
    zip = params[:zipcode]
    phone = params[:phone] # number_to_phone(params[:phone], :area_code => true)

    if zip.blank? || phone.blank?
      render :file => "public/422.html", :status => :unauthorized
      return
    end

    phone = phone.gsub(/\D/, '') 

    @scrape_tire_store = ScrapeTireStore.find_by_phone_and_zipcode(phone, zip)
    if @scrape_tire_store
      render :json => @scrape_tire_store
      return
    end

    phone = number_to_phone(params[:phone], :area_code => true)

    @lat, @lng = get_lat_lon_from_zip(zip)
    if @lat.nil? || @lng.nil?
      render :file => "public/422.html", :status => :unauthorized
      return
    end

    begin
      result = GooglePlaces::Request.spots({:keyword => "#{phone}", :key => google_places_api_key(), :location => "#{@lat}, #{@lng}", :radius => 10000})
      if result
        if result["results"].size == 1
          @place_id = result["results"][0]["place_id"]
          @client = GooglePlaces::Client.new(google_places_api_key())
          @google_place = @client.spot(@place_id)
          @scrape_tire_store = ScrapeTireStore.new 
          @scrape_tire_store.set_fields_from_google_place(@google_place)
          render :json => @scrape_tire_store
        else
          render :file => "public/422.html", :status => :unauthorized
          return
        end
      else
        render :file => "public/422.html", :status => :unauthorized
        return
      end
    rescue Exception => e
      render :file => "public/422.html", :status => :unauthorized
      return
    end
  end
  
  def get_checkout_info
    @phone = params[:phone]
    @email = params[:email]

    if (@phone.gsub(/\D/, '') =~ /(?:\+?|\b)[0-9]{10}\b/) == nil ||
      (@email =~ /\A([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i) == nil 
      # invalid phone or email
      respond_to do |format|
        @errors = {}
        @errors["err"] = "Please enter a valid email and phone number."
        format.html { render :json => @errors, :status => 500 }
      end
      return
    end
    @tire_listing = TireListing.find(params[:tire_listing_id])
    @order = Order.new(:tire_listing_id => params[:tire_listing_id], :tire_quantity => params[:quantity])
    if true || @tire_listing.can_do_ecomm?
      @order.calculate_total_order

      respond_to do |format|
        format.html { render :json => @order, 
                    :methods => [:total_order_price_money, :th_sales_tax_collected_money,
                                  :total_tire_price, :total_install_price_money, :th_user_fee_money_formatted,
                                  :sales_tax_collected_money_formatted, :sales_tax_on_tires_money,
                                  :sales_tax_on_install_money, :total_tire_price_money,
                                  :total_install_price_labor_money, :total_install_price_parts_money,
                                  :sales_tax_on_install_parts_money, :sales_tax_on_install_labor_money,
                                  :can_do_ecomm],
                    :include => [:tire_listing => {:except => [:price], :methods => [:can_do_ecomm?, :formatted_price, :photo1_thumbnail, :cost_per_tire, :manufacturer_name, :model_name, :sizestr, :mount_price]}] }
      end        
    else
      respond_to do |format|
        @errors = {}
        @errors["err"] = "This tire is not eligible for online purchase."
        format.html { render :json => @errors, :status => 500 }
      end
    end
  end

  def create_appointment
    @appointment = Appointment.new

    @tire_listing = TireListing.find(params[:tire_listing_id])
    @tire_store = @tire_listing.tire_store

    # this function should only be used to create an appointment that is going to be
    # used with an order.

    if false
      if !@tire_listing.can_do_ecomm?
        @errors = {}
        @errors["err"] = "This tire is not eligible for online purchase."
        respond_to do |format|
          format.html { render :json => @errors, :status => 500 }
        end
        return      
      end
    end

    @appointment.buyer_name = params[:buyer_name]
    @appointment.buyer_email = params[:buyer_email]
    @appointment.buyer_phone = params[:buyer_phone]
    @appointment.buyer_address = params[:buyer_address] ||= "unknown"
    @appointment.buyer_city = params[:buyer_city] ||= "unknown"
    @appointment.buyer_state = params[:buyer_state] ||= "GA"
    @appointment.buyer_zip = params[:buyer_zip] ||= "99999"
    @appointment.tire_store_id = @tire_store.id
    @appointment.tire_listing_id = @tire_listing.id
    @appointment.price = @tire_listing.price
    @appointment.quantity = params[:quantity]
    @appointment.preferred_contact_path = "phone"
    @appointment.request_date_primary = @appointment.request_date_secondary = params[:request_date_primary]
    @appointment.request_hour_primary = @appointment.request_hour_secondary = params[:request_hour_primary] # request_date_secondary

    begin
      if @appointment.save

        Notification.create_pending_appointment_confirmations(@appointment.tire_listing.tire_store_id)

        respond_to do |format|
          format.html { render :json => @appointment, :methods => [:can_do_ecomm] }
        end  
      else
        respond_to do |format|
          format.html { render :json => @appointment.errors, :status => 500 }
        end
      end
    rescue Exception => e 
        respond_to do |format|
          format.html { render :json => @appointment.errors, :status => 500 }
        end
    end
  end

  def create_order
    @tire_listing = TireListing.find_by_id(params[:tire_listing_id])
    if @tire_listing.nil?
        respond_to do |format|
          render :nothing => true, :status => :fail
        end
        return
    end

    @order = Order.new(:tire_listing_id => params[:tire_listing_id], :tire_quantity => params[:quantity])
    @order.status = order_status_array[:created]
    if @order.tire_quantity.to_i <= 0
      @order.tire_quantity = 4
    end
    @order.calculate_total_order
    @order.buyer_email = @order.buyer_name = @order.buyer_address1 = @order.buyer_city = @order.buyer_state = @order.buyer_zip = "unknown" # to prevent null error
    unless current_user.nil?
      @order.user_id = current_user.id
    end

    @order.appointment_id = params[:appointment_id]

    @order.buyer_name = params[:buyer_name] unless params[:buyer_name].blank?
    @order.buyer_email = params[:buyer_email] unless params[:buyer_email].blank?
    @order.buyer_phone = params[:buyer_phone] unless params[:buyer_phone].blank?

    ##@order.stripe_charge_token = params[:stripe_token]

    if !@order.stripe_buyer_customer_token.blank?
      begin
        @customer = Stripe::Customer.retrieve(@order.stripe_buyer_customer_token)
      rescue Exception => e
        # could not retrieve the customer record, so let's just re-create the customer
        @customer = nil 
        @order.stripe_buyer_customer_token = ""
      end
    end


    if @order.stripe_buyer_customer_token.blank?
      begin
        @customer = Stripe::Customer.create(:card => params[:stripe_token], :description => params[:buyer_email])
      rescue Exception => e
        respond_to do |format|
          @order.errors.add("exception", e.to_s)
          format.html { render :json => @order.errors, :status => 500 }
        end   
        @order.destroy
        return
      end
      @order.stripe_buyer_customer_token = @customer.id
      @order.uuid = SecureRandom.uuid
    elsif @customer.nil?
      @customer = Stripe::Customer.retrieve(@order.stripe_buyer_customer_token)
    end

    stripe_buyer_customer_cc_token = @customer.default_source #@customer.active_card.id

    @order.status = order_status_array[:ready_for_billing]
    @order.save

    @order.delay.bill_order

    respond_to do |format|
      format.html { render :json => @order }
    end    
  end

  def get_region_for_state(state_abbr)
    case state_abbr.upcase
      when "WV", "VA", "KY", "TN", "NC", "SC", "GA", "AL", "MS", "AR", "LA", "FL"
        "Southeast"
      when "ME", "MA", "RI", "CT", "NH", "VT", "NY", "PA", "NJ", "DE", "MD"
        "Northeast"
      when "OH", "IN", "MI", "IL", "MO", "WI", "MN", "IA", "KS", "NE", "SD", "ND"
        "Midwest"
      when "TX", "OK", "NM", "AZ"
        "Southwest"
      when "CO", "WY", "MT", "ID", "WA", "OR", "UT", "NV", "CA", "AK", "HI"
        "West"
      else
        "Southeast"
    end
  end

  def homepage_cities_by_state
    state_abbr = params[:state]
    
    if state_abbr.blank?
      lat = params[:lat] || ""
      lon = params[:lon] || ""
      location = params[:locationstr] || ""

      if lat.empty? && lon.empty? && !location.empty?
        state_abbr = get_state_from_location(location)
      elsif lat.to_s.empty? && lon.to_s.empty?
        state_abbr = get_state_from_ip_address(request.remote_ip)
      end

      if state_abbr.blank?
        render json: nil, status: 500
        return
      end
    end

    @lc ||= LearningCenter.new
    ar_cities = @lc.cities_for_state(state_abbr)
    if ar_cities 
        respond_to do |format|
          format.html { render :partial => 'layouts/homepage/cities_by_state', 
                                :locals => {:state_name => us_states.select{|ar| ar[1] == state_abbr}.first[0],
                                            :state_abbr => state_abbr,
                                            :cities => ar_cities}}  
        end     
    else
        render json: nil, status: 500
        return
    end
  end

  def homepage_cities_by_region
    state_abbr = params[:state]
    
    if state_abbr.blank?
      lat = params[:lat] || ""
      lon = params[:lon] || ""
      location = params[:locationstr] || ""

      if lat.empty? && lon.empty? && !location.empty?
        state_abbr = get_state_from_location(location)
      elsif lat.to_s.empty? && lon.to_s.empty?
        state_abbr = get_state_from_ip_address(request.remote_ip)
      end

      if state_abbr.blank?
        render json: nil, status: 500
        return
      end
    end

    region = get_region_for_state(state_abbr)
    @lc ||= LearningCenter.new
    ar_cities = @lc.cities_for_region(region)

    if ar_cities
      ar = ar_cities.in_groups(3)
      respond_to do |format|
        format.html { render :partial => 'layouts/homepage/cities_by_region', 
                              :locals => {:region_name => region,
                                          :ar_cities1 => ar.first,
                                          :ar_cities2 => ar.second,
                                          :ar_cities3 => ar.third}}
      end
      return
    else
      respond_to do |format|
        render json: nil, status: 500
      end
      return
    end
  end

  def homepage_local_promotions
    # we will try to get local promotions but if we can't, we'll get national ones
    lat = params[:lat]
    lon = params[:lon]
    location = params[:locationstr]

    begin
      if (lat.nil? || lat.empty?) && (lon.nil? || lon.empty?) && (location.nil? || !location.empty?)
        geo = []
        i = 0
        while geo.empty? && i <= 2
          geo = Geocoder.search(location)
          i = i + 1
        end
        if !geo.empty?
          if false
            lat, lon = geo.first.data["point"]["coordinates"]
          else
            lat = geo.first.data["geometry"]["location"]["lat"]
            lon = geo.first.data["geometry"]["location"]["lng"]
          end
        end
      end

      if lat.to_s.empty? && lon.to_s.empty?
        geo = []
        i = 0
        while geo.is_a?(Array) && geo.empty? && i <= 2
          geo = Geocoder.search(request.remote_ip)[0].data
          puts "Geo is #{geo}"
          i = i + 1
        end
        if geo["latitude"]
          lat, lon = geo["latitude"], geo["longitude"]
        end
      end

      @tire_store_ids = []

      if !lat.blank? && !lon.blank?
        # search with lat/long
        @promotions, @tire_store_ids = Promotion.local_and_national_promotions([lat, lon], 20, 4)
      elsif !locationstr.blank?
        @promotions, @tire_store_ids = Promotion.local_and_national_promotions(locationstr, 20, 4)
      else
        @promotions, @tire_store_ids = Promotion.local_and_national_promotions(nil, 0, 4)
      end

      if @tire_store_ids.nil?
        @tire_store_ids = []
      end

      if @promotions.nil? || @promotions.size == 0
        # need to render something here that fills the blank gap, but for now we'll just
        # render blank boxes

        respond_to do |format|
          format.html { render :partial => 'layouts/homepage/homepage_promotion', 
                                :locals => {:promo1_title => "",
                                            :promo1_location => "",
                                            :promo1_image_url => "",
                                            :promo2_title => "",
                                            :promo2_location => "",
                                            :promo2_image_url => "",
                                            :promo3_title => "",
                                            :promo3_location => "",
                                            :promo3_image_url => "",
                                            :promo4_title => "",
                                            :promo4_location => "",
                                            :promo4_image_url => ""}}
        end
      else
        @promo1 = @promotions[0] || Promotion.new(:promo_name => "")
        @promo2 = @promotions[1] || Promotion.new(:promo_name => "")
        @promo3 = @promotions[2] || Promotion.new(:promo_name => "")
        @promo4 = @promotions[3] || Promotion.new(:promo_name => "")

        if @promo1 && !@tire_store_ids.empty?
          if @promo1.promo_level == 'A'
            # account level rebate - find the store in our list that belongs to this account
            @account = Account.find(@promo1.account_id)
            @all_local_stores = @account.tire_store_ids & @tire_store_ids
            if @all_local_stores && @all_local_stores.size > 0
              @tire_store1 = TireStore.find(@all_local_stores.first)
              #@promo1.promo_name = "#{@tire_store1.name} - got first loc: #{@all_local_stores}"
            else
              @tire_store1 = TireStore.find(@tire_store_ids.first)  
              #@promo1.promo_name = "#{@tire_store1.name} - blah"
            end
          else
            @tire_store1 = TireStore.find(@tire_store_ids.first)
            #@promo1.promo_name = "#{@tire_store1.name} - dude"
          end
          @promo1_location = "#{@tire_store1.name} #{@tire_store1.zipcode}"
        else
          @promo1_location = ""
        end

        if @promo2 && !@tire_store_ids.empty?
          if @promo2.promo_level == 'A'
            # account level rebate - find the store in our list that belongs to this account
            @account = Account.find(@promo2.account_id)
            @all_local_stores = @account.tire_store_ids & @tire_store_ids
            if @all_local_stores && @all_local_stores.size > 0
              @tire_store2 = TireStore.find(@all_local_stores.first)
            else
              @tire_store2 = TireStore.find(@tire_store_ids.first)  
            end
          else
            @tire_store2 = TireStore.find(@tire_store_ids.first)
          end
          @promo2_location = "#{@tire_store2.name} #{@tire_store2.zipcode}"
        else
          @promo2_location = ""
        end

        if @promo3 && !@tire_store_ids.empty?
          if @promo3.promo_level == 'A'
            # account level rebate - find the store in our list that belongs to this account
            @account = Account.find(@promo3.account_id)
            @all_local_stores = @account.tire_store_ids & @tire_store_ids
            if @all_local_stores && @all_local_stores.size > 0
              @tire_store3 = TireStore.find(@all_local_stores.first)
            else
              @tire_store3 = TireStore.find(@tire_store_ids.first)  
            end
          else
            @tire_store3 = TireStore.find(@tire_store_ids.first)
          end
          @promo3_location = "#{@tire_store3.name} #{@tire_store3.zipcode}"
        else
          @promo3_location = ""
        end

        if @promo4 && !@tire_store_ids.empty?
          if @promo4.promo_level == 'A'
            # account level rebate - find the store in our list that belongs to this account
            @account = Account.find(@promo4.account_id)
            @all_local_stores = @account.tire_store_ids & @tire_store_ids
            if @all_local_stores && @all_local_stores.size > 0
              @tire_store4 = TireStore.find(@all_local_stores.first)
            else
              @tire_store4 = TireStore.find(@tire_store_ids.first)  
            end
          else
            @tire_store4 = TireStore.find(@tire_store_ids.first)
          end
          @promo4_location = "#{@tire_store4.name} #{@tire_store4.zipcode}"
        else
          @promo4_location = ""
        end

        respond_to do |format|
          format.html { render :partial => 'layouts/homepage/homepage_promotion', 
                                :locals => {:promo1_title => @promo1.promo_name,
                                            :promo1_location => @promo1_location,
                                            :promo1_image_url => @promo1.promo_image_url,
                                            :promo1_id => @promo1.id,
                                            :promo2_title => @promo2.promo_name,
                                            :promo2_location => @promo2_location,
                                            :promo2_image_url => @promo2.promo_image_url,
                                            :promo2_id => @promo2.id,
                                            :promo3_title => @promo3.promo_name,
                                            :promo3_location => @promo3_location,
                                            :promo3_image_url => @promo3.promo_image_url,
                                            :promo3_id => @promo3.id,
                                            :promo4_title => @promo4.promo_name,
                                            :promo4_location => @promo4_location,
                                            :promo4_image_url => @promo4.promo_image_url,
                                            :promo4_id => @promo4.id}}
        end
      end
    rescue Exception => e
      puts "Exception:******"
      puts e.to_s
      puts e.backtrace
      render :file => "public/422.html", :status => :unauthorized
      return
    end
  end

  def homepage_yelp_reviews_no_location
    respond_to do |format|
        format.html { render :partial => 'layouts/homepage/yelp_review', 
                              :locals => {:location => "Location Unavailable",
                                          :rating => "",
                                          :review_url => "",
                                          :store_name => "Location Unavailable",
                                          :review_text => "Please enable browser geolocation or enter location"}}
    end    
  end

  def homepage_google_reviews_no_location
    respond_to do |format|
        format.html { render :partial => 'layouts/homepage/google_review', 
                              :locals => {:location => "Location Unavailable",
                                          :rating => "",
                                          :review_url => "",
                                          :store_name => "Location Unavailable",
                                          :review_text => "Please enable browser geolocation or enter location"}}
    end    
  end

  def homepage_foursquare_reviews_no_location
    respond_to do |format|
        format.html { render :partial => 'layouts/homepage/foursquare_review', 
                              :locals => {:location => "Location Unavailable",
                                          :store_name => "Location Unavailable",
                                          :review_text => "Please enable browser geolocation or enter location",
                                          :review_author => "",
                                          :review_date => Time.now}}
    end
  end

  def get_lat_lon_from_location(location)
    lat = lon = ""
    geo = []
    i = 0
    while geo.empty? && i <= 2
      geo = Geocoder.search(location)
      i = i + 1
    end
    if !geo.empty?
      if false # bing
        lat, lon = geo.first.data["point"]["coordinates"]
      else
        lat = geo.first.data["geometry"]["location"]["lat"]
        lon = geo.first.data["geometry"]["location"]["lng"]
      end
    end

    return lat, lon
  end

  def get_lat_lon_from_ip_address(ip_address)
    lat, lon = ""
    geo = []
    i = 0
    while geo.is_a?(Array) && geo.empty? && i <= 2
      geo = Geocoder.search(ip_address)[0].data
      i = i + 1
    end
    if geo["latitude"] && !(geo["latitude"] == 38 && geo["longitude"] == -97) && !(geo["latitude"] == "0" && geo["longitude"] == "0")
      lat, lon = geo["latitude"], geo["longitude"]
    else
      lat, lon = ""
    end

    return lat, lon
  rescue Exception => e 
    return "", ""
  end

  def get_zipcode_from_location(location)
    zipcode = ""
    geo = []
    i = 0
    while geo.is_a?(Array) && geo.empty? && i <= 2
      geo = Geocoder.search(location)
      i = i + 1
    end

    if false
      if geo[0] && geo[0].data && geo[0].data["address"] && geo[0].data["address"]["adminDistrict"]
        zipcode = geo[0].data["address"]["adminDistrict"]
      elsif geo[0] && geo[0].data && geo[0].data["point"] && geo[0].data["point"]["coordinates"]
        zipcode = get_state_from_lat_lon(geo[0].data["point"]["coordinates"][0],geo[0].data["point"]["coordinates"][1])
      else
        zipcode = ""
      end
    else
      if geo[0] && geo[0].data && geo[0].data["address_components"]
        zipcode = ""
        geo[0].data["address_components"].each do |component|
          if component["types"][0] == "postal_code"
            zipcode = component["short_name"]
          end
        end

        # google doesn't give us a zipcode from city.
        if zipcode.blank?
          lat, lon = get_lat_lon_from_location(location)
          if lat.blank? || lon.blank?
            zipcode = ""
          else
            zipcode = get_zipcode_from_lat_lon(lat, lon)
          end
        end
      else
        zipcode = ""
      end
    end

    return zipcode
  end

  def get_state_from_location(location)
    state_abbr = ""
    geo = []
    i = 0
    while geo.is_a?(Array) && geo.empty? && i <= 2
      geo = Geocoder.search(location)
      i = i + 1
    end

    if false
      if geo[0] && geo[0].data && geo[0].data["address"] && geo[0].data["address"]["adminDistrict"]
        state_abbr = geo[0].data["address"]["adminDistrict"]
      elsif geo[0] && geo[0].data && geo[0].data["point"] && geo[0].data["point"]["coordinates"]
        state_abbr = get_state_from_lat_lon(geo[0].data["point"]["coordinates"][0],geo[0].data["point"]["coordinates"][1])
      else
        state_abbr = ""
      end
    else
      if geo[0] && geo[0].data && geo[0].data["address_components"]
        geo[0].data["address_components"].each do |component|
          if component["types"][0] == "administrative_area_level_1"
            state_abbr = component["short_name"]
          end
        end
      else
        state_abbr = ""
      end
    end

    return state_abbr
  end

  def get_zipcode_from_lat_lon(lat, lon)
    return get_zipcode_from_location("#{lat}, #{lon}")
  end
  
  def get_state_from_lat_lon(lat, lon)
    return get_state_from_location("#{lat}, #{lon}")
  end  

  def get_zipcode_from_ip_address(ip_address)
    zipcode = ""
    geo = []
    i = 0
    while geo.is_a?(Array) && geo.empty? && i <= 2
      geo = Geocoder.search(ip_address)[0].data
      i = i + 1
    end
    if geo[0] && geo[0].data
      zipcode = geo[0].data["address"]["postalCode"]
    else
      zipcode = ""
    end

    return zipcode
  end

  def get_state_from_ip_address(ip_address)
    state_abbr = ""
    geo = []
    i = 0
    while geo.is_a?(Array) && geo.empty? && i <= 2
      geo = Geocoder.search(ip_address)[0].data
      i = i + 1
    end
    if geo[0] && geo[0].data
      state_abbr = geo[0].data["address"]["adminDistrict"]
    else
      state_abbr = ""
    end

    return state_abbr
  end  

  def homepage_yelp_reviews
    @yelp_client = Yelp::Client.new({ consumer_key: 'zvkg62-vqZXqTeE2ykf07w',consumer_secret: 'xWxFiIBorCFGdHgc1YndhY58XVc',token: 'TSDqeY_6mLy5hvO64TOfK0e_7Hygkze0',token_secret: 'EYqdlcXo0Vd-u9n-c2PotNMA2WA'})

    lat = params[:lat] || ""
    lon = params[:lon] || ""
    location = params[:locationstr] || ""

    begin
      if lat.empty? && lon.empty? && !location.empty?
        lat, lon = get_lat_lon_from_location(location)
      end

      if lat.to_s.empty? && lon.to_s.empty?
        lat, lon = get_lat_lon_from_ip_address(request.remote_ip)
      end

      if lat.blank? && lon.blank?
        homepage_yelp_reviews_no_location
        return
      end

      @businesses = @yelp_client.search_by_coordinates({:latitude => lat, :longitude => lon}, { term: '', limit: 10, category_filter: 'tires'}, { lang: 'en' }).businesses

      # find the first venue with 'tips', which are reviews
      @business = nil
      @businesses.each do |b|
        if !b.snippet_text.blank?
          @business = b
          break
        end
      end
    rescue Exception => e 
      @business = nil 
      puts "Exception: #{e.to_s}"
      puts "#{e.backtrace}"
    end

    if @business.nil?
      respond_to do |format|
          format.html { render :partial => 'layouts/homepage/yelp_review', 
                                :locals => {:location => location,
                                            :store_name => "",
                                            :review_text => ""}}
      end
    else
      respond_to do |format|
          format.html { render :partial => 'layouts/homepage/yelp_review', 
                                :locals => {:location => @business.location.postal_code,
                                            :review_url => "http://www.yelp.com/search?find_desc=tires&find_loc=#{location}",
                                            :rating => @business.rating_img_url_large,
                                            :store_name => @business.name,
                                            :review_text => @business.snippet_text}}
      end
    end
  end

  def get_zipcode_from_ip_address(ip_address)
    zipcode = ""
    geo = []
    i = 0
    while geo.is_a?(Array) && geo.empty? && i <= 2
      geo = Geocoder.search(ip_address)[0].data
      i = i + 1
    end
    if geo[0] && g[0].data
      zipcode = g[0].data["address"]["postalCode"]
    else
      zipcode = ""
    end

    return zipcode
  end

  def homepage_google_reviews
    @yelp_client = Yelp::Client.new({ consumer_key: 'zvkg62-vqZXqTeE2ykf07w',consumer_secret: 'xWxFiIBorCFGdHgc1YndhY58XVc',token: 'TSDqeY_6mLy5hvO64TOfK0e_7Hygkze0',token_secret: 'EYqdlcXo0Vd-u9n-c2PotNMA2WA'})

    lat = params[:lat] || ""
    lon = params[:lon] || ""
    location = params[:locationstr] || ""
    zipcode = ""

    # google requires a zipcode or city/state, not lat/lon

    begin
      if lat.empty? && lon.empty? && !location.empty?
        zipcode = get_zipcode_from_location(location)
      end

      if lat.to_s.empty? && lon.to_s.empty? && zipcode.blank?
        zipcode = get_zipcode_from_ip_address(request.remote_ip)
      end

      if zipcode.blank? && !lat.blank? && !lon.blank?
        zipcode = get_zipcode_from_lat_lon(lat, lon)
      end

      if zipcode.blank?
        homepage_google_reviews_no_location
        return
      end

      @client = GooglePlaces::Client.new(google_places_api_key())

      puts "Searching for tire stores near #{zipcode}"

      @businesses = @client.spots_by_query("Tire Stores near #{zipcode}", :types => ['car_repair', 'store'])

      # find the first venue with 'tips', which are reviews
      @business = nil
      @businesses.each do |b|
        if b.rating
          @business = GooglePlaces::Spot.find(b.place_id, google_places_api_key())
          break
        end
      end
    rescue Exception => e 
      @business = nil 
      puts "Exception: #{e.to_s}"
      puts "#{e.backtrace}"
    end

    if @business.nil?
      respond_to do |format|
          format.html { render :partial => 'layouts/homepage/google_review', 
                                :locals => {:location => zipcode,
                                            :store_name => "Cannot find Google Places store",
                                            :rating => nil,
                                            :review_url => "",
                                            :review_text => ""}}
      end
    else
      respond_to do |format|
          format.html { render :partial => 'layouts/homepage/google_review', 
                                :locals => {:location => @business.postal_code,
                                            :review_url => "https://www.google.com/maps/search/tire+stores+near+#{zipcode}",
                                            :rating => nil,
                                            :store_name => @business.name,
                                            :review_text => @business.reviews.first.text + " -- " + @business.reviews.first.author_name}}
      end
    end
  end  

  def homepage_foursquare_reviews
    lat = params[:lat]
    lon = params[:lon]
    location = params[:locationstr]

    begin
      if lat.empty? && lon.empty? && !location.empty?
        lat, lon = get_lat_lon_from_location(location)
      end

      if lat.to_s.empty? && lon.to_s.empty?
        lat, lon = get_lat_lon_from_ip_address(request.remote_ip)
      end

      if lat.blank? && lon.blank?
        homepage_foursquare_reviews_no_location
        return
      end

      @four_square_client = Foursquare2::Client.new(:client_id => 'PPMWM3XXJJSQ14HFDEJLKBRKMEHLLCF5ZU1QBX1IFGBXBS2B', :client_secret => 'YCCQ0BLEBQ0KGKJB4PX4YTEQMR4PDRZE50OPAILCPMN1FUFP', :api_version => '20140806')
      @venues = @four_square_client.search_venues(:ll => "#{lat}, #{lon}", :query => 'tire stores', :categoryId => '4bf58dd8d48988d124951735')['venues']

      # find the first venue with 'tips', which are reviews
      @venue = nil
      @venues.each do |v|
        if v.stats["tipCount"] > 0 && v.location.formattedAddress[1] != "United States"
          @venue = v 
          break
        end
      end
    rescue Exception => e 
      @venue = nil 
    end
    if @venue.nil?
      respond_to do |format|
          format.html { render :partial => 'layouts/homepage/foursquare_review', 
                                :locals => {:location => "Unable to find FourSquare tire store in location",
                                            :store_name => "",
                                            :review_text => "",
                                            :review_author => "",
                                            :review_date => Time.now}}
      end
    else
      @review = @four_square_client.venue_tips(@venue.id).items.first
      respond_to do |format|
          format.html { render :partial => 'layouts/homepage/foursquare_review', 
                                :locals => {:location => @venue.location.formattedAddress[1],
                                            :review_url => "https://foursquare.com/explore?near=#{location}&q=tire%20stores",
                                            :store_name => @venue.name,
                                            :review_text => @review.text,
                                            :review_author => @review.user.firstName,
                                            :review_date => Time.at(@review.createdAt)}}
      end
    end
  end

  def display_faq_category
    @lc = LearningCenter.new 
    @cur_category = @lc.category_by_id(params[:category_id].to_i)
    if @cur_category.nil?
      render :nothing => true, :status => :fail
    else
      respond_to do |format|
        format.html { render :partial => 'learning_center/faq_category_details', 
                      :locals => {:@cur_category => @cur_category}}
      end
    end
  end

  def cancel_order
    @order = Order.find_by_id(params[:order_id])
    @reason = params[:reason]

    if @order.eligible_for_refund?
      if @order.refund_order(@reason)
        @order.appointment.reject_appointment
        respond_to do |format|
          format.html { render :json => @order }
        end  
      else
        respond_to do |format|
          @errors = {}
          @errors["err"] = @order.refund_fail_message
          puts "Error refunding order...#{@order.refund_fail_message}"
          format.html { render :json => @errors, :status => 500 }
        end
      end
    else
      respond_to do |format|
        @errors = {}
        @errors["err"] = "Order is not eligible for refund - status = #{@order.status}"
        puts "Order is not eligible for refund - status = #{@order.status}"
        format.html { render :json => @errors, :status => 500 }
      end
    end
  end
end
