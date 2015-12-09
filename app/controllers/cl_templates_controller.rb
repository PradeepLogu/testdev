class ClTemplatesController < ApplicationController
	before_filter :correct_user,   only: [:edit, :update, :show]
	include ClTemplatesHelper

  # GET /brandings/1/edit
  def edit
    @tire_store = TireStore.find(params[:tire_store_id])
    if @tire_store.account.can_use_mobile? && @tire_store.cl_template.nil?
      @cl_template = ClTemplate.new
      @cl_template.tire_store_id = @tire_store.id
      @cl_template.save
    end
    @cl_template = @tire_store.cl_template
  end

  def update
    @tire_store = TireStore.find(params[:tire_store_id])
    @cl_template = @tire_store.cl_template

    respond_to do |format|
      if @cl_template.update_attributes(params[:cl_template])
        format.html { redirect_to @tire_store, notice: 'Template was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @cl_template.errors, status: :unprocessable_entity }
      end
    end
  end
end
