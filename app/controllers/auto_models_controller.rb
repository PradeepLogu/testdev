class AutoModelsController < ApplicationController
  # GET /auto_models
  # GET /auto_models.json
  def index
    @auto_models = AutoModel.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @auto_models }
    end
  end

  # GET /auto_models/1
  # GET /auto_models/1.json
  def show
    @auto_model = AutoModel.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @auto_model }
    end
  end

  # GET /auto_models/new
  # GET /auto_models/new.json
  def new
    @auto_model = AutoModel.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @auto_model }
    end
  end

  # GET /auto_models/1/edit
  def edit
    @auto_model = AutoModel.find(params[:id])
  end

  # POST /auto_models
  # POST /auto_models.json
  def create
    @auto_model = AutoModel.new(params[:auto_model])

    respond_to do |format|
      if @auto_model.save
        format.html { redirect_to @auto_model, notice: 'Auto model was successfully created.' }
        format.json { render json: @auto_model, status: :created, location: @auto_model }
      else
        format.html { render action: "new" }
        format.json { render json: @auto_model.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /auto_models/1
  # PUT /auto_models/1.json
  def update
    @auto_model = AutoModel.find(params[:id])

    respond_to do |format|
      if @auto_model.update_attributes(params[:auto_model])
        format.html { redirect_to @auto_model, notice: 'Auto model was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @auto_model.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /auto_models/1
  # DELETE /auto_models/1.json
  def destroy
    @auto_model = AutoModel.find(params[:id])
    @auto_model.destroy

    respond_to do |format|
      format.html { redirect_to auto_models_url }
      format.json { head :no_content }
    end
  end
end
