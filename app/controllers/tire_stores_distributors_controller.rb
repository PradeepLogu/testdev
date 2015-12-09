include TireStoresHelper

class TireStoresDistributorsController < ApplicationController
	before_filter :correct_user

	def update
		@tire_store = TireStore.find(params[:tire_stores_distributor][:tire_store_id])
		@distributor = Distributor.find(params[:tire_stores_distributor][:distributor_id])
		if @tire_store && @distributor
			@xref_rec = TireStoresDistributor.find_or_create_by_tire_store_id_and_distributor_id(@tire_store.id, @distributor.id)
			
			# because these are virtual attributes, they cannot be mass-assigned.  So let's
			# assign them individually then remove them.
			@xref_rec.password = params[:tire_stores_distributor][:password]
			@xref_rec.password_confirmation = params[:tire_stores_distributor][:password_confirmation]

			params[:tire_stores_distributor].delete(:password)
			params[:tire_stores_distributor].delete(:password_confirmation)

			@xref_rec.update_attributes(params[:tire_stores_distributor])

			@xref_rec.tire_manufacturers = ""
			#@xref_rec.save
			if !params[:tire_manufacturers].nil?
				params[:tire_manufacturers].each do |manu_id|
					@xref_rec.add_tire_manufacturer_id(manu_id)
				end
			end

			saved = false
			begin
				saved = @xref_rec.save
			rescue
				saved = false
			end
			if saved
				respond_to do |format|
					#format.html { render action: "show" }
					flash[:notice] = "Distributor Info was successfully updated."
					#format.html { render action: "edit", controller: :tire_stores}
					format.html { redirect_to edit_tire_store_path(@tire_store) }
				end
			else
				respond_to do |format|
					if @xref_rec.errors.count == 0
						flash[:alert] = "Error saving record - you may need to select at least one manufacturer."
					else
						flash[:alert] = "Error saving: #{@xref_rec.errors.full_messages.join(', ').html_safe}"
					end
					format.html { render action: "edit" }
				end
			end
		end
	end

	def create
		update
	end

	def edit
	    if !signed_in?
	      set_return_path(request.fullpath)      
	      redirect_to signin_path, notice: "Please sign in."
	      return
	    end
    
		@tire_store = TireStore.find_by_id(params[:tire_store_id])
		@distributor = Distributor.find_by_id(params[:distributor_id])
		if @tire_store && @distributor
			@xref_rec = TireStoresDistributor.find_or_create_by_tire_store_id_and_distributor_id(@tire_store.id, @distributor.id)
			@xref_rec.errors.clear
		else
			flash[:alert] = "Invalid store or distributor."
			redirect_to_back()
		end
	end
end