class AutoManufacturersController < ApplicationController
  # GET /auto_manufacturers
  # GET /auto_manufacturers.json
  def index
    @auto_manufacturers = AutoManufacturer.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @auto_manufacturers }
    end
  end

  # GET /auto_manufacturers/1
  # GET /auto_manufacturers/1.json
  def show
    @auto_manufacturer = AutoManufacturer.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @auto_manufacturer }
    end
  end

  # GET /auto_manufacturers/new
  # GET /auto_manufacturers/new.json
  def new
    @auto_manufacturer = AutoManufacturer.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @auto_manufacturer }
    end
  end

  # GET /auto_manufacturers/1/edit
  def edit
    @auto_manufacturer = AutoManufacturer.find(params[:id])
  end

  # POST /auto_manufacturers
  # POST /auto_manufacturers.json
  def create
    @auto_manufacturer = AutoManufacturer.new(params[:auto_manufacturer])

    respond_to do |format|
      if @auto_manufacturer.save
        format.html { redirect_to @auto_manufacturer, notice: 'Auto manufacturer was successfully created.' }
        format.json { render json: @auto_manufacturer, status: :created, location: @auto_manufacturer }
      else
        format.html { render action: "new" }
        format.json { render json: @auto_manufacturer.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /auto_manufacturers/1
  # PUT /auto_manufacturers/1.json
  def update
    @auto_manufacturer = AutoManufacturer.find(params[:id])

    respond_to do |format|
      if @auto_manufacturer.update_attributes(params[:auto_manufacturer])
        format.html { redirect_to @auto_manufacturer, notice: 'Auto manufacturer was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @auto_manufacturer.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /auto_manufacturers/1
  # DELETE /auto_manufacturers/1.json
  def destroy
    @auto_manufacturer = AutoManufacturer.find(params[:id])
    @auto_manufacturer.destroy

    respond_to do |format|
      format.html { redirect_to auto_manufacturers_url }
      format.json { head :no_content }
    end
  end
end
