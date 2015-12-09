class TireSizesController < ApplicationController
  # GET /tire_sizes
  # GET /tire_sizes.json
  def index
    @tire_sizes = TireSize.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @tire_sizes }
    end
  end

  def diameters
    @tire_diameters = TireSize.find(:all, :select => "DISTINCT diameter", :order => :diameter)

    respond_to do |format|
      format.json { render json: @tire_diameters }
    end
  end

  def ratios
    @tire_ratios = TireSize.where('diameter = ?', params[:diameter]).select('DISTINCT (ratio)').order(:ratio)

    #(:all, :select => "DISTINCT ratio", :order => :ratio, :where => "diameter = " + params[:diameter])

    respond_to do |format|
      format.json { render json: @tire_ratios }
    end
  end

  def wheeldiameters
    @tire_wheeldiameters = TireSize.where('diameter = ? and ratio = ?', 
          params[:diameter], params[:ratio]).select('wheeldiameter, id').order(:wheeldiameter)

    #(:all, :select => "DISTINCT ratio", :order => :ratio, :where => "diameter = " + params[:diameter])

    respond_to do |format|
      format.json { render json: @tire_wheeldiameters }
    end
  end

  # GET /tire_sizes/1
  # GET /tire_sizes/1.json
  def show
    @tire_size = TireSize.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @tire_size }
    end
  end

  # GET /tire_sizes/new
  # GET /tire_sizes/new.json
  def new
    @tire_size = TireSize.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @tire_size }
    end
  end

  # GET /tire_sizes/1/edit
  def edit
    @tire_size = TireSize.find(params[:id])
  end

  # POST /tire_sizes
  # POST /tire_sizes.json
  def create
    @tire_size = TireSize.new(params[:tire_size])

    respond_to do |format|
      if @tire_size.save
        format.html { redirect_to @tire_size, notice: 'Tire size was successfully created.' }
        format.json { render json: @tire_size, status: :created, location: @tire_size }
      else
        format.html { render action: "new" }
        format.json { render json: @tire_size.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /tire_sizes/1
  # PUT /tire_sizes/1.json
  def update
    @tire_size = TireSize.find(params[:id])

    respond_to do |format|
      if @tire_size.update_attributes(params[:tire_size])
        format.html { redirect_to @tire_size, notice: 'Tire size was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @tire_size.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tire_sizes/1
  # DELETE /tire_sizes/1.json
  def destroy
    @tire_size = TireSize.find(params[:id])
    @tire_size.destroy

    respond_to do |format|
      format.html { redirect_to tire_sizes_url }
      format.json { head :no_content }
    end
  end
end
