
class TireSearchesController < ApplicationController
  include ApplicationHelper
  include TireSearchesHelper
  
  before_filter :correct_user,   only: [:edit, :update, :destroy]

  # GET /tire_searches
  # GET /tire_searches.json

  def saved_searches
    if signed_in?
      @saved_searches = current_user.saved_searches
      respond_to do |format|
        format.html
      end
    else
      if request && request.referer
        redirect_to request.referer, notice: 'You must sign in first.'
      else
        redirect_to '/', notice: 'You must sign in first.'
      end
    end
  end

  # GET /tire_searches/1
  # GET /tire_searches/1.json
  def show
    @tire_search = TireSearch.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @tire_search }
    end
  end

  # GET /tire_searches/new
  # GET /tire_searches/new.json
  def new
    @tire_search = TireSearch.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @tire_search }
    end
  end

  # DG - Same as search results, but only gets tire stores and displays them (no tire listings)
  def storeresults
    @display_mode = "stores"
    #params[:radius] = (params[:radius] && TireSearch::RADIUS_CHOICES.include?(params[:radius]) ? params[:radius] : "10")
    
    tireresults
  end
  
  def searchresults
    tireresults
  end

  def tireresults
    @display_mode ||= "listings"
    backtrace_log if backtrace_logging_enabled

    # basic error checking
    @manufacturers = TireManufacturer.order("name")
    
    @tire_search = get_tire_search_from_params
    
    size_search = !params[:size_search].nil?
    auto_search = !params[:auto_search].nil?
    model_search = !params[:model_search].nil?

    begin
      backtrace_log if backtrace_logging_enabled
      if auto_search
        if !@tire_search.auto_options_id
          raise "Please select Make, Model, Year, and Options."
        end
        @tire_search.tire_size_id = AutoOption.find(@tire_search.auto_options_id).tire_size_id

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
        @form_mode = "auto_search"
      elsif model_search
        @tire_search.tire_size.diameter = nil
        @tire_search.tire_size.ratio = nil
        @tire_search.tire_size.wheeldiameter = nil
        @tire_search.auto_manufacturer_id = nil
        @tire_search.auto_model_id = nil
        @tire_search.auto_year_id = nil
        @tire_search.auto_options_id = nil
        session[:diameter] = nil
        session[:ratio] = nil
        session[:wheeldiameter] = nil
        session[:manufacturer_id] = nil
        session[:auto_model_id] = nil
        session[:auto_year_id] = nil
        session[:option_id] = nil
        @form_mode = "model_search"
        
        if @tire_search.tire_model_id.nil?
          raise "No tire model selected."
        end
        #model = TireModel.includes(:tire_size).find(@tire_search.tire_model_id)
        #@tire_search.tire_size = model.tire_size
      else
        unless @tire_search.tire_size.nil?
          sizestr = sprintf('%g', @tire_search.tire_size.diameter.blank? ? 0 : @tire_search.tire_size.diameter) + 
                              '/' + sprintf('%g', @tire_search.tire_size.ratio.blank? ? 0 : @tire_search.tire_size.ratio) + 
                              'R' + sprintf('%g', @tire_search.tire_size.wheeldiameter.blank? ? 0 : @tire_search.tire_size.wheeldiameter) 
        end
        ts = TireSize.find_by_sizestr(sizestr)
        raise "Invalid tiresize: " + sizestr if ts.nil?

        @tire_search.tire_size_id = TireSize.find_by_sizestr(sizestr).id

        session[:manufacturer_id] = nil
        @tire_search.auto_manufacturer_id = nil
        session[:auto_model_id] = nil
        @tire_search.auto_model_id = nil
        session[:auto_year_id] = nil
        @tire_search.auto_year_id = nil
        session[:option_id] = nil
        @tire_search.auto_options_id = nil
        session[:diameter] = @tire_search.tire_size.diameter
        session[:ratio] = @tire_search.tire_size.ratio
        session[:wheeldiameter] = @tire_search.tire_size.wheeldiameter
        @form_mode = "size_search"
      end
    
      backtrace_log if backtrace_logging_enabled

      session[:location] = @tire_search.locationstr unless @tire_search.locationstr.blank?
      session[:radius] = @tire_search.radius unless @tire_search.radius.blank?
      session[:quantity] = @tire_search.quantity.to_s 
      session[:new_or_used] = @tire_search.new_or_used

      @tire_search.user_id = current_user.id if signed_in?

      raise "Could not determine location" if not @tire_search.valid_geography?

      # DG 7/16/15 - Need to modify this section to take into account new ways of searching... 
      if !params['o'] && !@tire_search.tire_size_id.nil?
        # see if we can find an existing saved search for this user.  If so, then we don't
        # need to offer them to save again.
        if signed_in?
          backtrace_log if backtrace_logging_enabled
          @existing_search = TireSearch.where('user_id = ? and tire_size_id = ? and locationstr = ? and radius = ? and saved_search_frequency <> ?',
                                              current_user.id, @tire_search.tire_size_id, @tire_search.locationstr,
                                              @tire_search.radius, '').first
        end
        @tire_search.save

        backtrace_log if backtrace_logging_enabled
      end

      session[:mylatitude] = @tire_search.latitude
      session[:mylongitude] = @tire_search.longitude

      backtrace_log if backtrace_logging_enabled
      
      if @display_mode != "stores"
        @tire_stores = @tire_search.tirelistings.sort{|a,b| a.tire_store.visible_name.downcase <=> b.tire_store.visible_name.downcase}.map{|a| {:id => a.tire_store_id, :name => a.tire_store.visible_name}}.inject(Hash.new(0)) {|h,x| h[x]+=1;h}   
        @quantities = @tire_search.tirelistings.sort{|a,b| a.quantity <=> b.quantity}.map{|a| {:qty => a.quantity}}.inject(Hash.new(0)) {|h,x| h[x]+=1;h}
        @tire_manufacturers = @tire_search.tirelistings.sort{|a,b| a.tire_manufacturer_name <=> b.tire_manufacturer_name}.map{|a| {:id => a.tire_manufacturer_id,
                                                                  :name => a.tire_manufacturer_name}}.inject(Hash.new(0)) {|h,x| h[x]+=1;h}
        @categories = @tire_search.tirelistings.sort{|a,b| (a.tire_category and b.tire_category) ? a.tire_category.category_name <=> b.tire_category.category_name : (a.tire_category.nil? ? -1 : 1)}.map{|a| {:id => (a.tire_category ? a.tire_category.id : 0), :category => (a.tire_category ? a.tire_category.category_name : 'n/a')}}.inject(Hash.new(0)) {|h,x| h[x]+=1;h}
        @sellers = @tire_search.tirelistings.sort{|a,b| (a.tire_store.private_seller.to_s <=> b.tire_store.private_seller.to_s)}.map{|a| {:type => (a.tire_store.private_seller ? 'Private Sellers' : 'Storefronts'), :val => a.tire_store.private_seller}}.inject(Hash.new(0)) {|h,x| h[x]+=1;h}
        ###@pictures = @tire_search.tirelistings.sort{|a,b| (a.photo1_thumbnail.nil?.to_s <=> b.photo1_thumbnail.nil?.to_s)}.map{|a| {:type => (a.photo1_thumbnail.nil? ? 'Listings without pictures' : 'Listings with pictures'), :val => a.photo1_thumbnail.nil?}}.inject(Hash.new(0)) {|h,x| h[x]+=1;h}
        @conditions = @tire_search.tirelistings.sort{|a,b| (a.is_new.to_s <=> b.is_new.to_s)}.map{|a| {:type => (a.is_new ? 'New' : 'Used'), :val => a.is_new}}.inject(Hash.new(0)) {|h,x| h[x]+=1;h}
      end
      
      backtrace_log if backtrace_logging_enabled

    rescue Exception => e 
      flash[:error] = e.message 
      e.backtrace.each do |s|
        logger.info(s)
      end

      if !request.env["HTTP_REFERER"].blank? && request.env["HTTP_REFERER"] != request.env["REQUEST_URI"]
        redirect_to :back
      else
        redirect_to '/'
      end
    end
  end

  # GET /tire_searches/1/edit
  def edit
    @tire_search = TireSearch.find(params[:id])
  end

  def get_tire_search_from_params
    @tire_search = TireSearch.new
    @tire_search.tire_size = TireSize.new
    
    # DG - These nested attributes happen when creating a form using "fields_for :tire_size"
    if !params["tire_search"].nil? && !params["tire_search"]["tire_size_attributes"].nil?
      params["tire_search"].merge!(params["tire_search"]["tire_size_attributes"])
      params["tire_search"].delete("tire_size_attributes")
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
      if params[:tire_manufacturer_id] != nil
        @tire_search.tire_manufacturer_id = params[:tire_manufacturer_id]
      elsif !params["tire_search"].nil? && params["tire_search"]["tire_manufacturer_id"] != nil
        @tire_search.tire_manufacturer_id = params["tire_search"]["tire_manufacturer_id"]
      end
    rescue
      #@tire_search.tire_manufacturer_id = 0
    end
    
    begin
      if params[:tire_model_id] != nil
        @tire_search.tire_model_id = params[:tire_model_id]
      elsif !params["tire_search"].nil? && params["tire_search"]["tire_model_id"] != nil
        @tire_search.tire_model_id = params["tire_search"]["tire_model_id"]
      end
    rescue
      #@tire_search.tire_model_id = 0
    end
    
    begin
      if params[:tire_size_id] != nil
        @tire_search.tire_size.id = params[:tire_size_id]
      elsif !params["tire_search"].nil? && params["tire_search"]["tire_size_id"] != nil
        @tire_search.tire_size.id = params["tire_search"]["tire_size_id"]
      end
    rescue
      @tire_search.tire_size.id = 0
    end

    begin
      if params[:new_or_used] != nil
        @tire_search.new_or_used = params[:new_or_used]
      elsif !params["tire_search"].nil? && params["tire_search"]["new_or_used"] != nil
        @tire_search.new_or_used = params["tire_search"]["new_or_used"]
      else
          params.each do |param|
            @tire_search.new_or_used = param[1]["new_or_used"] if not param.nil? and not param[1]["new_or_used"].blank?
          end
      end
    rescue
      @tire_search.new_or_used = 'b'
    end

    begin
      if params[:locationstr] != nil
        @tire_search.locationstr = params[:locationstr]
        puts '1 - just set locationstr to ' + @tire_search.locationstr
      elsif !params["tire_search"].nil? && params["tire_search"]["locationstr"] != nil
        @tire_search.locationstr = params["tire_search"]["locationstr"]
        puts '2 - just set locationstr to ' + @tire_search.locationstr
      else
          #params.each do |param|
          #  if not param.nil? and not param[1]["locationstr"].blank?
          #    @tire_search.locationstr = param[1]["locationstr"] 
          #    puts '3 - just set locationstr to ' + @tire_search.locationstr
          #  end
          #end
      end
    rescue
      @tire_search.locationstr = ''
      puts '4 - had an exception - resetting locationstr to nil'
    end

    begin
      if !params[:radius].blank?
        @tire_search.radius = params[:radius]
      elsif !params["tire_search"].nil? && !params["tire_search"]["radius"].blank?
        @tire_search.radius = params["tire_search"]["radius"]
      else
          params.each do |param|
            @tire_search.radius = param[1]["radius"] if not param.nil? and not param[1]["radius"].blank?
          end
      end

      if @tire_search.radius.to_i <= 0
        @tire_search.radius = '20'
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

  # POST /tire_searches
  # POST /tire_searches.json

  def create
    @tire_search = TireSearch.new(params[:tire_search])

    respond_to do |format|
      if @tire_search.save
        format.html { redirect_to  URI::encode(@tire_search.search_link), notice: 'Saved search was successfully created.' }
        format.json { render json: @tire_search, status: :created, location: @tire_search }
      else
        format.html { render action: "new" }
        format.json { render json: @tire_search.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /tire_searches/1
  # PUT /tire_searches/1.json
  def update
    @tire_search = TireSearch.find(params[:id])

    respond_to do |format|
      if @tire_search.update_attributes(params[:tire_search])
        format.html { redirect_to '/saved_searches', notice: 'Saved search was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @tire_search.errors, status: :unprocessable_entity }
      end
    end
  end    

  def ajax_url
    params = instance_variables.grep(/_filter$/).map{|m| "#{m}=#{instance_variable_get(m)}" unless instance_variable_get(m).nil?}.compact.join().gsub(/\@/, "&")
    "/tire_searches/#{self.id}?ajax=true#{params}"
  end

  def filter_link(key, value)
    if self.respond_to?(key)
      "#{ajax_url}&#{key}=#{value}"
    elsif self.respond_to?("#{key}_filter")
      "#{ajax_url}&#{key}_filter=#{value}"
    end
  end

  # DELETE /tire_searches/1
  # DELETE /tire_searches/1.json
  def destroy
    @tire_search = TireSearch.find(params[:id])
    @tire_search.destroy

    respond_to do |format|
      format.html { redirect_to '/saved_searches' }
      format.json { head :no_content }
    end
  end

  def update_models
    # updates models based on manufacturer selected
    @manufacturer = AutoManufacturer.find(params[:manufacturer_id])
    @models = @manufacturer.auto_models.order(:name)
    @years = AutoYear.where('id = 0')
    @options = AutoOption.where('id = 0')
    
    respond_to do |format|
      #format.html { escape_javascript(render(:partial => 'layouts/test', :layout => false)) }
      #format.html { render :partial => 'layouts/test', :object => @models, :locals => {:f => @tire_search}, :layout => false }
      format.html { render :partial => 'layouts/models', :object => @models, :locals => {:f => @tire_search}, :layout => false }
      
      #format.html { render :partial => 'layouts/models', :object => @models, :locals => {:f => @tire_search}, :layout => false }
    end
  end
  
  def update_years
    # updates years based on manufacturer and model selected
    @model = AutoModel.find(params[:model_id])
    @years = @model.auto_years
    @options = AutoOption.where('id = 0')

    render :update do |page|
      page.replace_html 'years', :partial => 'layouts/years', :object => @years, :locals => {:f => @tire_search}
      page.replace_html 'options', :partial => 'layouts/options', :object => @options, :locals => {:f => @tire_search}
    end
  end

  def update_options
    # updates options based on manufacturer, model, and year selected
    @year = AutoYear.find(params[:auto_year_id])
    @options = @year.auto_options

    render :update do |page|
      page.replace_html 'options', :partial => 'layouts/options', :object => @options, :locals => {:f => @tire_search}
    end
  end

  def update_ratios
    # updates the aspect ratio and wheel diameter drop lists when diameter (section width) changes
    @ratios = TireSize.all_ratios(params[:diameter])

    render :update do |page|
      page.replace_html 'ratios', :partial => 'layouts/ratios', :object => @ratios, :locals => {:f => @tire_search}
    end
  end

  def update_wheeldiameters
    # updates the aspect ratio and wheel diameter drop lists when diameter (section width) changes
    @wheeldiameters = TireSize.all_wheeldiameters(params[:ratio])

    render :update do |page|
      page.replace_html 'wheeldiameters', :partial => 'layouts/wheeldiameters', :object => @wheeldiameters, :locals => {:f => @tire_search}
    end
  end
end
