class TireStoreWarehouseTier < ActiveRecord::Base
	attr_accessible :tire_store_id, :warehouse_id, :warehouse_tier_id

	def create_or_update_tire_listings
		@start_time = Time.now

		@tire_store = TireStore.find(self.tire_store_id)
		@warehouse = Warehouse.find(self.warehouse_id)
		@warehouse_tier = WarehouseTier.find(self.warehouse_tier_id)

		@all_prices = WarehousePrice.find_all_by_warehouse_id_and_warehouse_tier_id(self.warehouse_id, self.warehouse_tier_id)

		@all_manu_markups = TireStoreMarkup.find(:all, :conditions => ['tire_store_id = ? and warehouse_id = ? and tire_manufacturer_id > 0', self.tire_store_id, self.warehouse_id])
		@all_model_info_markups = TireStoreMarkup.find(:all, :conditions => ['tire_store_id = ? and warehouse_id = ? and tire_model_info_id > 0', self.tire_store_id, self.warehouse_id])
		@all_size_markups = TireStoreMarkup.find(:all, :conditions => ['tire_store_id = ? and warehouse_id = ? and tire_size_id > 0', self.tire_store_id, self.warehouse_id])
		@all_model_markups = TireStoreMarkup.find(:all, :conditions => ['tire_store_id = ? and warehouse_id = ? and tire_model_id > 0', self.tire_store_id, self.warehouse_id])

		@total_created = 0
		@total_updated = 0
		@total_skipped_manual_override = 0
		@total_skipped_unchanged = 0
		@total_skipped_because_cheaper_elsewhere = 0
		@total_no_markup = 0

		@email_log = []

		# process all the warehouse price records
		@all_prices.each do |warehouse_price|
			# a warehouse_price record is the wholesale price that the store pays, we need
			# to mark it up using the appropriate markup

			# find the proper markup record...go from most specific to least specific
			@markups = []

			@markups = @all_model_markups.select{|m| m.tire_model_id = warehouse_price.tire_model_id}

			if @markups.empty?
				@markups = @all_size_markups.select{|m| m.tire_size_id = warehouse_price.tire_model.tire_size_id}
			end

			if @markups.empty?
				@markups = @all_model_info_markups.select{|m| m.tire_model_info_id = warehouse_price.tire_model.tire_model_info_id}
			end

			if @markups.empty?
				@markups = @all_manu_markups.select{|m| m.tire_manufacturer_id = warehouse_price.tire_model.tire_manufacturer_id}
			end

			if !@markups.empty?
				# we shouldn't have multiples but who knows...
				@markup = @markups.first

				@markup_money = @markup.markup_wholesale_price_as_money(warehouse_price.wholesale_price)

				# see if we can find a listing for this store and tire model
				@tire_listing = TireListing.find_by_tire_store_id_and_tire_model_id_and_is_new(self.tire_store_id, warehouse_price.tire_model_id, true)
				if @tire_listing.nil?
					@tire_listing = TireListing.new 
					@tire_listing.tire_store_id = self.tire_store_id
					@tire_listing.source = "WarehousePricing"
        			@tire_listing.quantity = 4 # use actual number????
        			@tire_listing.tire_manufacturer_id = warehouse_price.tire_model.tire_manufacturer_id
					@tire_listing.tire_model_id = warehouse_price.tire_model_id
        			@tire_listing.tire_size_id = warehouse_price.tire_model.tire_size_id
        			@tire_listing.includes_mounting = false
			        @tire_listing.is_new = true

			        @total_created += 1
			    else
			    	# check and see if this listing was manually entered.
			    	# if it was manual, do not update it.
			    	if @tire_listing.price_source.to_i > 0
			    		puts "Skipping because manual override."
			    		@total_skipped_manual_override += 1
			    		next
			    	end

			    	# now check and see if the price has changed.  if not, then
			    	# we don't need to update anything.
			    	if ('%.2f' % @tire_listing.price) == ('%.2f' % @markup_money)
			    		puts "Skipping because price hasn't changed."
			    		@total_skipped_unchanged += 1
			    		next 
			    	end

			    	# finally, if the existing price came from another warehouse and is lower,
			    	# we will use that one.
			    	if !@tire_listing.price_source.nil? && @tire_listing.price_source.to_i == 0 &&
			    		!@tire_listing.warehouse_price_id.nil? && 
			    		@tire_listing.warehouse_price_id != warehouse_price.id
			    		@total_skipped_because_cheaper_elsewhere += 1
			    		puts "Skipping because it's cheaper from another supplier."
			    		next 
			    	end
	        	end
    			@tire_listing.price = @markup_money
    			@tire_listing.price_source = 0
				@tire_listing.warehouse_price_id = warehouse_price.id
				@tire_listing.price_updated_at = Time.now

				puts "Marking up #{warehouse_price.wholesale_price.to_s} to #{@tire_listing.price.to_s} (#{@markup.markup_pct})"

				if !@tire_listing.new_record?
					@total_updated += 1
				end

				@tire_listing.save
			else
				@total_no_markup += 1
			end
		end

		@end_time = Time.now

		@tot_runtime_seconds = @end_time - @start_time

		@runtime_minutes = (@tot_runtime_seconds / 60).floor
		@runtime_seconds = (@tot_runtime_seconds - (@runtime_minutes * 60)).round(0)

		@email_log << "Finished updating the prices on tire listings from #{@warehouse.name} (#{@warehouse.city}, #{@warehouse.state})"
		@email_log << ""
		@email_log << "Store name: #{@tire_store.name}"
		@email_log << "Store address: #{@tire_store.full_address}"
		@email_log << "The process took #{@runtime_minutes} minutes and #{@runtime_seconds} seconds."
		@email_log << ""
		@email_log << "Records created: #{@total_created}"
		@email_log << "Records updated: #{@total_updated}"
		@email_log << "Records skipped because a listing existed with a price override: #{@total_skipped_manual_override}"
		@email_log << "Records skipped because the price hasn't changed: #{@total_skipped_unchanged}"
		@email_log << "Records skipped because a different supplier has a cheaper price: #{@total_skipped_because_cheaper_elsewhere}"
		@email_log << ""

		# should this go to the store as well???
		ActionMailer::Base.delay.mail(:from => "mail@treadhunter.com", 
			:to => system_process_completion_email_address(), 
			:subject => "Updated Pricing from #{@warehouse.name} (#{@warehouse.city}, #{@warehouse.state})",
			:body => @email_log.join("\n"))
	rescue Exception => e 
		@email_log.insert(0, "ERROR #{e.to_s} running create_or_update_tire_listings for id=#{self.id}.")
		ActionMailer::Base.delay.mail(:from => "mail@treadhunter.com", 
			:to => system_process_completion_email_address(), 
			:subject => "Error updating prices from warehouse", 
			:body => @email_log.join("\n"))
	end
end