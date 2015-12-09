class WarehouseTier < ActiveRecord::Base
	attr_accessible :cost_pct_from_base, :tier_name, :warehouse_id

	def update_customer_prices
		@tire_store_xrefs = TireStoreWarehouseTier.find_all_by_warehouse_id_and_warehouse_tier_id(self.warehouse_id, self.id)
		@tire_store_xrefs.each do |xref|
			xref.delay.create_or_update_tire_listings
		end
	end

	def markup_wholesale_price_as_money(raw_price)
		price = raw_price.to_money

		return price + (price * (self.cost_pct_from_base / 100.00))
	end

	def self.create_tier_pricing_from_base(warehouse_id, base_tier_name="base")
		@base_warehouse_tier = WarehouseTier.find_by_warehouse_id_and_tier_name(warehouse_id, base_tier_name)

		@pricing_records = WarehousePrice.find(:all, :conditions => ['warehouse_id = ? and warehouse_tier_id = ?', warehouse_id, @base_warehouse_tier.id])

		@other_warehouse_tiers = WarehouseTier.find(:all, :conditions => ['warehouse_id = ? and id <> ?', warehouse_id, @base_warehouse_tier.id])
		@other_warehouse_tiers.each do |t|
			@pricing_records.each do |base_price|
				new_price = base_price.dup
				new_price.warehouse_tier_id = t.id
				new_price.base_price_warehouse_price_id = base_price.id
				new_price.base_price = base_price.base_price
				new_price.cost_pct_from_base = t.cost_pct_from_base
				new_price.wholesale_price = t.markup_wholesale_price_as_money(base_price.base_price)

				new_price.save
			end
		end
	end

	# note: this is really only to be used for testing, not something we'll ever actually call
	# so we might call this on a WarehouseTier named "base" to create base pricing records.
	def import_my_tier_pricing_from_tci(markdown_pct = -20.0, create_other_tier_records = true)
		# first, check to see if we are a TCI record
		tci_name = Distributor.tci_distributor_name

		my_warehouse = Warehouse.find_by_id(self.warehouse_id)
		if !my_warehouse
			message = "WarehouseTier record id: #{self.id} - trying to run import_my_tier_pricing_from_tci but there is no TCI Warehouse with ID=#{self.warehouse_id}"

			# create a super user notification
			Notification.create_super_user_notification(message, "TCI Pricing Import Error", 120000, Time.now + 3.days, 5, "error")

			return false, message
		end

		email_log = []

		email_log << "Importing TCI base pricing data for Warehouse=#{my_warehouse.name} (#{my_warehouse.city}, #{my_warehouse.state})"
		email_log << ""
		email_log << "Tier name is #{self.tier_name}:"

		tci = TCIInterface.new

		total_added = 0
		total_updated = 0
		total_not_updated = 0

		TireSize.find(:all).each do |size|
				search_size = size.sizestr.scan(/(\d*)\/*(\d*)R*(\d*)/).join('')

				tire_manufacturer_ids = TireManufacturer.all.map{|m| m.id}
			
		        client = Savon.client(wsdl: "http://www.tcitips.com/Websales/cfc/TCi_SearchSizeTIPS.cfc?wsdl",
		        						logger: Rails.logger)
		        response = ""
		        (0..5).each do |i|
		        	begin
		        		response = client.call :search_by_size, 
		                	                :message => { 
		                                    param_User: '4330167',
		                                    param_Pass: 'd73nfsyd',
		                                    param_Size: search_size#,
		                                    #param_Brand: 7
		                                    #param_QuoteBack: '',
		                                }
	 				rescue HTTPClient::ConnectTimeoutError => e 
	 					# ignore...
	 					response = ""
	 					sleep(5)
	 					next
	 				rescue SocketError => e 
	 					response = ""
	 					sleep(5)
	 					next
					rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
       					Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
	 					response = ""
	 					sleep(5)
	 					next
	 				rescue Exception => e
	 					throw e
	 				end
	 			end
	 			if response.to_s == ""
	 				puts "There seem to have been a lot of timeouts...try later"
	 				email_log << "There seem to have been a lot of timeouts...try later"
	 				break
	 			end
		        doc = REXML::Document.new(response.to_xml.to_s)
		        #puts "*** DOC: #{doc}"
		        doc.elements.each('//tire') do |tire|
		            #puts "***TIRE IS A #{tire.class}"
		            tciPN = tire.get_elements('tciPN').first.text
		            manuPN = tire.get_elements('manuPN').first.text
		            tire_vendor = tire.get_elements('vendor').first.text

		            tipsmainprice = tire.get_elements('tipsmainprice').first.text
		            tipsdiscprice = tire.get_elements('tipsdiscprice').first.text
		            price = tire.get_elements('price').first.text

		            qty = tire.get_elements('invqty').first.text.to_i

		            manus = tci.get_th_manu_id_from_tci_vendor_no(tire_vendor)

		            if !manuPN.nil?
			            manus.each do |manu_id|
			            	if tire_manufacturer_ids.include?(manu_id)
				            	tm = TireModel.find_by_tire_manufacturer_id_and_product_code(manu_id, manuPN)

				            	# some of the Pirelli models start with three zeros on the TCI site, but our
				            	# database doesn't have them.
				            	tm = TireModel.find_by_tire_manufacturer_id_and_product_code(manu_id, manuPN.sub(/^000/, '')) if tm.nil?

				            	# Maxxis may start with "TP"
								tm = TireModel.find_by_tire_manufacturer_id_and_product_code(manu_id, "TP" + manuPN, '') if tm.nil?		            	

				            	if !tm.nil?
				            		puts "#{tm.tire_manufacturer.name}\t#{tm.description}\t#{price}\t#{tipsdiscprice}\t#{tipsmainprice}"

				            		# do we have an existing pricing record?  if so, we might
				            		# want to update it if the price has changed.  if not, create one.
				            		pricing_record = WarehousePrice.find_by_warehouse_id_and_warehouse_tier_id_and_tire_model_id(self.warehouse_id, self.id, tm.id)
				            		if !pricing_record
				            			total_added += 1

				            			base_price_money = price.to_money
				            			marked_down_price_money = base_price_money + (base_price_money * (markdown_pct / 100.00))		            			

				            			pricing_record = WarehousePrice.new 
				            			pricing_record.warehouse_id = self.warehouse_id 
				            			pricing_record.warehouse_tier_id = self.id 
				            			pricing_record.tire_model_id = tm.id 
				            			pricing_record.base_price_warehouse_price_id = nil 
				            			pricing_record.base_price = marked_down_price_money
				            			pricing_record.cost_pct_from_base = 0.0
				            			pricing_record.wholesale_price = marked_down_price_money

				            			pricing_record.save 
				            		else
				            			if price.to_money == pricing_record.wholesale_price.to_money
				            				total_not_updated += 1
				            			else
				            				total_updated += 1
				            				pricing_record.wholesale_price = price
				            				pricing_record.save
				            			end
				            		end
				            	end
				            end
						end
					end
	        	end
		end


		email_log << ""
		email_log << "Total added: #{total_added}"
		email_log << "Total updated: #{total_updated}"
		email_log << "Total not updated: #{total_not_updated}"

		ActionMailer::Base.delay.mail(:from => "mail@treadhunter.com", 
			:to => system_process_completion_email_address(), 
			:subject => "Imported TCI tier pricing data", 
			:body => email_log.join("\n"))

		# we now have the base prices imported, let's create tier prices for all other tiers
		if create_other_tier_records
			WarehouseTier.delay.create_tier_pricing_from_base(self.warehouse_id, "base")
		end
	end
end
