class TiresController < ApplicationController
  # GET /tires
  # GET /tires.json
  def index
    @tires = Tire.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @tires }
    end
  end

  # GET /tires/1
  # GET /tires/1.json
  def show
    @tire = Tire.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @tire }
    end
  end

  # GET /tires/new
  # GET /tires/new.json
  def new
    @tire = Tire.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @tire }
    end
  end

  # GET /tires/1/edit
  def edit
    @tire = Tire.find(params[:id])
  end

  # POST /tires
  # POST /tires.json
  def create
    @tire = Tire.new(params[:tire])

    respond_to do |format|
      if @tire.save
        format.html { redirect_to @tire, notice: 'Tire was successfully created.' }
        format.json { render json: @tire, status: :created, location: @tire }
      else
        format.html { render action: "new" }
        format.json { render json: @tire.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /tires/1
  # PUT /tires/1.json
  def update
    @tire = Tire.find(params[:id])

    respond_to do |format|
      if @tire.update_attributes(params[:tire])
        format.html { redirect_to @tire, notice: 'Tire was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @tire.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tires/1
  # DELETE /tires/1.json
  def destroy
    @tire = Tire.find(params[:id])
    @tire.destroy

    respond_to do |format|
      format.html { redirect_to tires_url }
      format.json { head :no_content }
    end
  end
end
