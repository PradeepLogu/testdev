class TireManufacturersController < ApplicationController
  # GET /tire_manufacturers
  # GET /tire_manufacturers.json
  def index
    @tire_manufacturers = TireManufacturer.order(:name)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @tire_manufacturers }
    end
  end

  # mobile
  def models_by_size
    @tire_size = TireSize.find_by_sizestr(params[:diameter] + '/' + params[:ratio] + 'R' + params[:wheeldiameter])

    unless @tire_size.nil?
      @tire_manufacturer = TireManufacturer.find_by_name(CGI::unescape(params[:manufacturer_name]))
      unless @tire_manufacturer.nil?
        @tire_models = TireModel.find_all_by_tire_manufacturer_id_and_tire_size_id(@tire_manufacturer.id, @tire_size.id)

        @tire_models.each do |t|
          t.name = t.name_and_product_code
        end

        respond_to do |format|
          format.json { render :json => @tire_models, :except => [:orig_cost], :methods => [:formatted_orig_cost]}
        end
      else
        respond_to do |format|
          format.json { render :json => []}
        end
      end
    else
      respond_to do |format|
        format.json { render :json => []}
      end
    end
  end  

  #mobile
  def model_lookup
    @tire_size = TireSize.find_by_sizestr(params[:diameter] + '/' + params[:ratio] + 'R' + params[:wheeldiameter])

    unless @tire_size.nil?
      @tire_manufacturer = TireManufacturer.find_by_name(CGI::unescape(params[:manufacturer_name]))
      unless @tire_manufacturer.nil?
        model_name = CGI::unescape(params[:model_name])
        @tire_model = TireModel.find_by_tire_manufacturer_id_and_tire_size_id_and_name(@tire_manufacturer.id, @tire_size.id, model_name)
        if @tire_model.nil?
          # this could be in the format #{name} (#{load}#{speed} #{product_code})
          @tire_model = TireModel.search_by_tire_manufacturer_id_and_tire_size_id_and_name_and_product_code(@tire_manufacturer.id, @tire_size.id, model_name)
        end

        if @tire_model
          respond_to do |format|
            format.json { render :json => @tire_model, :except => [:orig_cost], :methods => [:formatted_orig_cost]}
          end
        else
          respond_to do |format|
            format.json { render :json => []}
          end
        end 
      else
        respond_to do |format|
          format.json { render :json => []}
        end
      end
    else
      respond_to do |format|
        format.json { render :json => []}
      end
    end
  end

  # GET /tire_manufacturers/tire_models/:tire_manufacturer_id.json
  def tire_models
    if params[:id].to_i.to_s == params[:id]
      @tire_manufacturer = TireManufacturer.find(params[:id])
    else
      @tire_manufacturer = TireManufacturer.find_by_name(params[:id])
    end
    @tire_models = @tire_manufacturer.tire_models unless @tire_manufacturer.nil?
    respond_to do |format|
      format.json { render :json => @tire_models, :except => [:orig_cost], :methods => [:formatted_orig_cost]}
    end
  end

  # GET /tire_manufacturers/1
  # GET /tire_manufacturers/1.json
  def show
    @tire_manufacturer = TireManufacturer.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @tire_manufacturer }
    end
  end

  # GET /tire_manufacturers/new
  # GET /tire_manufacturers/new.json
  def new
    @tire_manufacturer = TireManufacturer.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @tire_manufacturer }
    end
  end

  # GET /tire_manufacturers/1/edit
  def edit
    @tire_manufacturer = TireManufacturer.find(params[:id])
  end

  # POST /tire_manufacturers
  # POST /tire_manufacturers.json
  def create
    @tire_manufacturer = TireManufacturer.new(params[:tire_manufacturer])

    respond_to do |format|
      if @tire_manufacturer.save
        format.html { redirect_to @tire_manufacturer, notice: 'Tire manufacturer was successfully created.' }
        format.json { render json: @tire_manufacturer, status: :created, location: @tire_manufacturer }
      else
        format.html { render action: "new" }
        format.json { render json: @tire_manufacturer.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /tire_manufacturers/1
  # PUT /tire_manufacturers/1.json
  def update
    @tire_manufacturer = TireManufacturer.find(params[:id])

    respond_to do |format|
      if @tire_manufacturer.update_attributes(params[:tire_manufacturer])
        format.html { redirect_to @tire_manufacturer, notice: 'Tire manufacturer was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @tire_manufacturer.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tire_manufacturers/1
  # DELETE /tire_manufacturers/1.json
  def destroy
    @tire_manufacturer = TireManufacturer.find(params[:id])
    @tire_manufacturer.destroy

    respond_to do |format|
      format.html { redirect_to tire_manufacturers_url }
      format.json { head :no_content }
    end
  end
end
