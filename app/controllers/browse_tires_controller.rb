class BrowseTiresController < ApplicationController
  
  CAR_TYPE_NAMES = {
    'car_minivan' => 'Car/Minivan',
    'crossover' => 'Crossover/CUV',
    'suv' => 'SUV',
    'truck' => 'Truck'
  }
  
  CAR_TYPE_OPTIONS = [
    ['Pick a Car Type', ''],
    ['Car/Minivan', 'car_minivan'],
    ['Crossover/CUV', 'crossover'],
    ['SUV', 'suv'],
    ['Truck', 'truck']
  ]
  
  def search
    if !params[:brand].blank?
      brand = TireManufacturer.where('LOWER(name) = ?', params[:brand].strip.downcase).first
      if brand
        redirect_to "/brands/#{brand.id}"
      else
        @brand_search_error = "No matching brand name found."
      end
    end
    
    if !params[:size].blank?
      size = /\A(\d{1,2}(?:\.\d{1,2})?)"?\z/.match(params[:size].strip)
      if !size.nil? && size[1]
        redirect_to "/tire_size/#{size[1]}"
      else
        @size_search_error = "Not a valid tire size."
      end
    end
    
    if !params[:type].blank? && CAR_TYPE_NAMES[ params[:type] ]
      redirect_to "/car_make/#{params[:type]}"
    end
    
    @car_type_options = CAR_TYPE_OPTIONS
    load_default_search_data()

    # this is needed because the search panel works with a tiresearch object
    @tire_search = TireSearch.new
    @user = current_user

    @lc = LearningCenter.new
    @page_seo = @lc.seo_browse_tires_page_posts
  end
  
  
  ##### Pages for browse by state/city #####
  
  def states
    @states = us_states.drop(1)
    @tire_search = TireSearch.new

    load_default_search_data()
  end
  
  def cities_in_state
    @state_name = @state = ''
    
    if !params[:state].blank?
      s = us_states.drop(1).select { |s| s[1] == params[:state] }
      if !s.empty?
        @state_name = s[0][0]
        @state = s[0][1]
      end
    end
    
    if @state.blank?
      redirect_to "/states"
    end
    
    @cities = TireStore.select("DISTINCT(city)").where(state: @state).order(:city)

    @tire_search = TireSearch.new

    load_default_search_data()
  end
  
  
  ##### Pages for browse by car type #####
  
  def car_type
    load_default_search_data()
    @tire_search = TireSearch.new
    @user = current_user

    @lc = LearningCenter.new
    @page_seo = @lc.seo_browse_by_car_type_page_posts    
  end
  
  def car_make
    @car_type = CAR_TYPE_NAMES[ params[:type] ]
    
    if @car_type.nil?
      redirect_to "/car_type"
    end
    
    load_default_search_data()
    @makes = @manufacturers
    @tire_search = TireSearch.new
    @user = current_user
  end
  
  def car_model
    @manufacturer = AutoManufacturer.find(params[:make])
    if !@manufacturer
      redirect_to "/car_type"
    end
    
    @car_type = @manufacturer.name
    @car_models = AutoModel.where(auto_manufacturer_id: @manufacturer.id).order(:name)
    
    load_default_search_data()
    @tire_search = TireSearch.new
    @user = current_user
  end
  
  def car_year
    @model = AutoModel.includes(:auto_manufacturer).find(params[:model])
    if !@model
      redirect_to "/car_type"
    end
    
    @car_type = @model.auto_manufacturer.name + ' ' + @model.name
    @car_years = AutoYear.where(auto_model_id: @model.id).order(:modelyear).reverse_order
    
    load_default_search_data()
    @tire_search = TireSearch.new
    @user = current_user
  end
  
  def car_option
    @year = AutoYear.includes(:auto_model).find(params[:year])
    if !@year
      redirect_to "/car_type"
    end
    
    @car_type = @year.modelyear + ' ' + @year.auto_model.auto_manufacturer.name + ' ' + @year.auto_model.name
    @car_options = AutoOption.where(auto_year_id: @year.id).order(:name)
    
    @default_locationstr = get_default_locationstr
    
    load_default_search_data()
    @tire_search = TireSearch.new
    @user = current_user
  end
  
  
  ##### Pages for browse by tire size #####
  
  def tire_wheeldiameter
    @all_diameters = TireSize.all_wheeldiameters(nil)
    
    load_default_search_data()
    @tire_search = TireSearch.new
    @user = current_user
  end
  
  def tire_width
    @wheeldiameter = params[:wheeldiameter].to_f
    if @wheeldiameter <= 0
      redirect_to "/tire_size", notice: "Wheel diameter not found."
      return
    end

    @widths = TireSize.where(wheeldiameter: @wheeldiameter)
                      .select("DISTINCT(diameter), wheeldiameter").order(:diameter)
    
    if @widths.blank?
      redirect_to "/tire_size", notice: "Wheel diameter not found."
      return
    end
    
    load_default_search_data()
    @tire_search = TireSearch.new
    @user = current_user
  end
  
  def tire_ratio
    @sizes = TireSize.where(wheeldiameter: params[:wheeldiameter], diameter: params[:diameter])
                     .order(:sizestr)
    
    if @sizes.blank?
      redirect_to "/tire_size/#{params[:wheeldiameter]}", notice: "Tire width not found."
    end
    
    @wheeldiameter = params[:wheeldiameter]   #@sizes.first.wheeldiameter
    @diameter = params[:diameter]     #@sizes.first.diameter
    @default_locationstr = get_default_locationstr
    
    load_default_search_data()
    @tire_search = TireSearch.new
    @user = current_user
  end
  
  
  private
  #Default text in the zipcode modal
  def get_default_locationstr
    session[:location] if /\A\d{5}\z/.match(session[:location])
  end
  
  def load_default_search_data
    @manufacturers = AutoManufacturer.order("name")
    @models = AutoModel.where(:auto_manufacturer_id => session[:manufacturer_id])
    @years = AutoYear.where(:auto_model_id => session[:auto_model_id])
    @options = AutoOption.where(:auto_year_id => session[:auto_year_id])

    @diameters = TireSize.all_diameters
    @ratios = TireSize.all_ratios(session[:diameter])
    @wheeldiameters = TireSize.all_wheeldiameters(session[:ratio])

    #if (!session[:diameter].blank?)
    #  @default_tab = 2
    #else
    #  @default_tab = 1
    #end

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
end
