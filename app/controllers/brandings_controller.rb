class BrandingsController < ApplicationController
	before_filter :correct_user,   only: [:edit, :update, :show]
	include BrandingsHelper

  # GET /brandings/1/edit
  def edit
    @tire_store = TireStore.find(params[:tire_store_id])
    if @tire_store.account.can_use_logo? && @tire_store.branding.nil?
      @branding = Branding.new
      @branding.tire_store_id = @tire_store.id
      @branding.save
    end
    @branding = @tire_store.branding
  end

  def update
    @tire_store = TireStore.find(params[:tire_store_id])
    @branding = @tire_store.branding
    if !@branding
    	@branding = Branding.new
    	@branding.tire_store_id = @tire_store.id
    end

    respond_to do |format|
      if @branding.update_attributes(params[:branding])
        format.html { redirect_to @tire_store, notice: 'Storefront was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @tire_store.errors, status: :unprocessable_entity }
      end
    end
  end
end
