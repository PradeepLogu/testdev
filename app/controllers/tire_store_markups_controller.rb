class TireStoreMarkupsController < ApplicationController
	def update_multiple
	end

	def edit_multiple
		@tire_store = TireStore.find(params[:tire_store_id])
		@warehouse = Warehouse.find(params[:warehouse_id])

		@start_time = Time.now.utc

		# this is convoluted...ruby gives an error if we use the same "fields_for" so we have to use
		# two.  And if we're adding new ones, it comes in as an array, if updating it's a hash.
		if params[:markups].is_a? Hash 
			@update_markups = []
			params[:markups].each do |k, v|
				@update_markups << v
			end
		else
			@update_markups = params[:markups] || []
		end

		if params[:new_markups].is_a? Hash 
			@new_markups = []
			params[:new_markups].each do |k, v|
				@new_markups << v
			end
		else
			@new_markups = params[:new_markups] || []
		end
		
		@markups = @update_markups + @new_markups

		@markups.each do |hash|
			if !hash[:tire_manufacturer_id].blank? && hash[:skip].blank?
				tm = TireManufacturer.find_by_id(hash[:tire_manufacturer_id])
				if !tm.nil?
					if hash[:id].blank?
						@markup = TireStoreMarkup.new
						@markup.tire_store_id = @tire_store.id
						@markup.warehouse_id = @warehouse.id
						@markup.tire_manufacturer_id = hash[:tire_manufacturer_id]

						if !hash[:tire_category_id].blank?
							@markup.tire_category_id = hash[:tire_category_id]
							@markup.markup_pct = hash[:markup_tire_category_id]
						elsif !hash[:tire_size_id].blank?
							@markup.tire_size_id = hash[:tire_size_id]
							@markup.markup_pct = hash[:markup_tire_size_id]
						elsif !hash[:tire_model_info_id].blank?
							@markup.tire_model_info_id = hash[:tire_model_info_id]
							@markup.markup_pct = hash[:markup_tire_model_info_id]
						else
							@markup.markup_pct = hash[:markup_pct]
						end
						@markup.markup_type = 0

						@markup.save if !@markup.markup_pct.blank?
					else
						# existing record...let's find and update
						@markup = TireStoreMarkup.find_by_id(hash[:id])
						if @markup.nil?
							@markup = TireStoreMarkup.create(:tire_store_id => @tire_store.id, 
										:warehouse_id => @warehouse.id,
										:markup_type => 0,
										:tire_manufacturer_id => hash[:tire_manufacturer_id])
						end
						if @markup
							if !hash[:tire_category_id].blank?
								@markup.tire_category_id = hash[:tire_category_id]
								@markup.markup_pct = hash[:markup_tire_category_id]
							elsif !hash[:tire_size_id].blank?
								@markup.tire_size_id = hash[:tire_size_id]
								@markup.markup_pct = hash[:markup_tire_size_id]
							elsif !hash[:tire_model_info_id].blank?
								@markup.tire_model_info_id = hash[:tire_model_info_id]
								@markup.markup_pct = hash[:markup_tire_model_info_id]
							else
								@markup.markup_pct = hash[:markup_pct]
							end
							@markup.save if !@markup.markup_pct.blank?

							@markup.touch # force a timestamp update
						end
					end
				end
			end
		end

		# the last step is to delete any markups that were deleted and thus not updated here.
		if @markups.count > 0
			@old_markups = TireStoreMarkup.find(:all, :conditions => ['tire_store_id = ? and warehouse_id = ? and updated_at < ?', @tire_store.id, @warehouse.id, @start_time])
			@old_markups.each do |m|
				puts "Deleting #{m.id} because updated_at (#{m.updated_at}) is older than #{@start_time}"
				m.destroy
			end
		end

		# now we need to create a cross reference record for the tire store and warehouse
		tsw = TireStoreWarehouse.find_or_create_by_tire_store_id_and_distributor_id_and_warehouse_id(@tire_store.id, @tire_store.distributor_import.distributor_id, @warehouse.id)

		# now a new warehouse tier record
		wt = WarehouseTier.find_or_create_by_warehouse_id_and_tier_name(@warehouse.id, @tire_store.distributor_import.distributor_tier)

		# now create a TireStoreWarehouseTier record
		tswt = TireStoreWarehouseTier.find_or_create_by_tire_store_id_and_warehouse_id_and_warehouse_tier_id(@tire_store.id, @warehouse.id, wt.id)

		respond_to do |format|
			if params[:next] == "stripe"
				format.html {redirect_to :action => :connect_with_stripe, :controller => :welcome}
			else
				format.html {redirect_to "/myTreadHunter"}
			end
		end
	end
end