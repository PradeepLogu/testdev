class ModelSearchesController < ApplicationController
  
  def index
    @tire_brands = TireManufacturer.order(:name)
    
    load_default_search_data()

    @lc = LearningCenter.new
    @brand_seo = @lc.seo_brands_page_posts
    
    # this is needed because the search panel works with a tiresearch object
    @tire_search = TireSearch.new
    @user = current_user
  end
  
  def showbrand
    begin
      @brand = TireManufacturer.find(params[:brand_id])
      
      @categories = @brand.get_all_tgp_tire_categories()   #Collect all tire model / tire category combinations
      types = @brand.get_all_car_types()                   #Collect all tire model / car type combinations
      
      #Turn the car types hash into an array because it needs to always have a specific order
      @car_types = []
      ['P', 'LT', 'Z'].each do |code|
        @car_types << {:code => code, :models => types[code]} if !types[code].nil?
      end
      @combined_passenger_models = types['P-Z'] || []
      
      load_default_search_data()
  
      # this is needed because the search panel works with a tiresearch object
      @tire_search = TireSearch.new
      @user = current_user
      
    rescue Exception => e
      flash[:error] = "Invalid brand ID."
      e.backtrace.each do |s|
        logger.info(s)
      end
      
      redirect_to '/brands'
    end
  end
  
  def showmodel
    begin
      @show_tire_reviews = false
      @default_locationstr = get_default_locationstr
      
      @model_info = TireModelInfo.includes(:tire_manufacturer).find(params[:model_id])
      if @default_locationstr.blank?
        @models = TireModel.includes(:tire_size, :tire_category).where(tire_model_info_id: @model_info.id)
                         .order('tire_sizes.sizestr ASC')
        @model_info[:starting_cost] = 0
      else
        @models = TireModel.includes(:tire_size, :tire_category).where(tire_model_info_id: @model_info.id)
                         .order('tire_sizes.sizestr ASC')
        # this will get the "starting at..." at the top
        @listings = TireListing.near(@default_locationstr).where("tire_model_id in (?) and is_new = true", @models.map{|x| x.id}).sort_by{|x| x.price.to_f}
        if @listings.size > 0
          @model_info[:starting_cost] = @listings.first.price
        else
          @model_info[:starting_cost] = 0
        end
      end
      
      @stock_photo = nil
      if !@model_info.stock_photo1_file_name.blank?
        if !@model_info.stock_photo1_file_name.start_with?('open-uri')
          @stock_photo = "stock_photos/#{@model_info.tire_manufacturer.name}/images/#{@model_info.stock_photo1_file_name}"
        end
      end

      # this is needed for the "Buy Now" button for each tire size listed
      @tire_search = TireSearch.new

      @user = current_user
      
    rescue Exception => e
      flash[:error] = "Invalid tire model."
      e.backtrace.each do |s|
        logger.info(s)
      end
      
      if !request.env['HTTP_REFERER'].blank? && request.env['HTTP_REFERER'] != request.env['HTTP_REFERER']
        redirect_to :back
      else
        redirect_to '/brands'
      end
    end
  end
  
  def category_results
    begin
      @brand = TireManufacturer.find(params[:brand_id])
      @brand.tgp_category_id_filter = params[:category_id]
      @models = @brand.tire_models
      
      @categories, @wheelsizes = create_mappings(@models)
      @cur_category_id = params[:category_id]
      @category_name = @models.first.get_tgp_category_name
      
      @default_locationstr = get_default_locationstr
      
      # this is needed for the "Buy Now" button for each tire model listed
      @tire_search = TireSearch.new
      @user = current_user
      
    rescue Exception => e
      flash[:error] = (@brand ? "Invalid category." : "Invalid ID.")
      e.backtrace.each do |s|
        logger.info(s)
      end
      
      if @brand
        redirect_to "/brands/#{@brand.id}"
      else
        redirect_to '/brands'
      end
    end
  end
  
  
  private
  #Default text in the zipcode modal
  def get_default_locationstr
    session[:location] if /\A\d{5}\z/.match(session[:location])
  end
  
  def load_default_search_data
    @manufacturers = AutoManufacturer.order(:name)
    @models = AutoModel.where(:auto_manufacturer_id => session[:manufacturer_id])
    @years = AutoYear.where(:auto_model_id => session[:auto_model_id])
    @options = AutoOption.where(:auto_year_id => session[:auto_year_id])

    @diameters = TireSize.all_diameters
    @ratios = TireSize.all_ratios(session[:diameter])
    @wheeldiameters = TireSize.all_wheeldiameters(session[:ratio])

    if session[:location].blank?
      # let's try to set based on geoip
      begin
        loc = Geocoder.search(request.remote_ip)[0]
        if loc && !loc.city.blank?
          session[:location] = loc.city + ', ' + loc.state
        end
      rescue
        puts "**** EXCEPTION"
      end
    end

    nil
  end
  
  def create_mappings(listings)
    categories = wheelsizes = []
    h = nil
    #Rack::MiniProfiler.step("mapping all") do
      h = listings.map{|m| [[m.tgp_category_id, m.tgp_category_id.nil? ? "N/A" : m.get_tgp_category_name], [m.tire_size.wheeldiameter, m.tire_size.wheeldiameter.to_s]]}
                  .inject(Hash.new) {|h,x| h['cat'] = Hash.new(0) if h['cat'].nil?; h['cat'][x[0]]+=1; h['wheelsize'] = Hash.new(0) if h['wheelsize'].nil?; h['wheelsize'][x[1]]+=1; h}
    #end

    #Rack::MiniProfiler.step("sorting all") do
      categories = h['cat'].sort_by{|k,v| k[1]} unless h['cat'].nil?
      wheelsizes = h['wheelsize'].sort_by{|k,v| k[1]} unless h['wheelsize'].nil?
    #end

    return categories, wheelsizes  
  end
end
