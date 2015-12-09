class AutoYearsController < ApplicationController
  # GET /auto_years
  # GET /auto_years.json
  def index
    @auto_years = AutoYear.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @auto_years }
    end
  end

  # GET /auto_years/1
  # GET /auto_years/1.json
  def show
    @auto_year = AutoYear.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @auto_year }
    end
  end

  # GET /auto_years/new
  # GET /auto_years/new.json
  def new
    @auto_year = AutoYear.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @auto_year }
    end
  end

  # GET /auto_years/1/edit
  def edit
    @auto_year = AutoYear.find(params[:id])
  end

  # POST /auto_years
  # POST /auto_years.json
  def create
    @auto_year = AutoYear.new(params[:auto_year])

    respond_to do |format|
      if @auto_year.save
        format.html { redirect_to @auto_year, notice: 'Auto year was successfully created.' }
        format.json { render json: @auto_year, status: :created, location: @auto_year }
      else
        format.html { render action: "new" }
        format.json { render json: @auto_year.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /auto_years/1
  # PUT /auto_years/1.json
  def update
    @auto_year = AutoYear.find(params[:id])

    respond_to do |format|
      if @auto_year.update_attributes(params[:auto_year])
        format.html { redirect_to @auto_year, notice: 'Auto year was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @auto_year.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /auto_years/1
  # DELETE /auto_years/1.json
  def destroy
    @auto_year = AutoYear.find(params[:id])
    @auto_year.destroy

    respond_to do |format|
      format.html { redirect_to auto_years_url }
      format.json { head :no_content }
    end
  end
end
