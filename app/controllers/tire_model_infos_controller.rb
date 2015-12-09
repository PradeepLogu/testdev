class TireModelInfosController < ApplicationController
	def index
		if params[:only_missing]
			@models = TireModelInfo.includes(:tire_manufacturer).find(:all, 
				:conditions => "photo1_url is null", :order => 'tire_manufacturers.name, tire_model_infos.tire_model_name')
		else			
			@models = TireModelInfo.includes(:tire_manufacturer).find(:all, 
				:order => 'tire_manufacturers.name, tire_model_infos.tire_model_name')
		end
	end

	def update
		@model = TireModelInfo.find(params[:id])

		respond_to do |format|
			if @model.update_attributes(params[:tire_model_info])
				format.html { redirect_to tire_model_infos_path, 
								notice: 'Tire model was successfully updated.',
								:only_missing => params[:only_missing] }
				format.json { head :no_content }
			else
				format.html { render action: "edit" }
				format.json { render json: @model.errors, status: :unprocessable_entity }
			end
		end
	end
end