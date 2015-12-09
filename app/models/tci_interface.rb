class TCIInterface
	def get_searchsize(sizestr)
		sizestr.scan(/(\d*)\/*(\d*)R*(\d*)/).join('')
	end

	def get_tci_brand(brand_name)
		case brand_name.downcase
			when "BF Goodrich".downcase
				"001"
			when "BFGoodrich".downcase
				"001"
			when "Trivant".downcase
				"002"
			when "Michelin".downcase
				"003"
			when "Yokohama".downcase
				"004"
			when "Uniroyal".downcase
				"005"
			when "Continental".downcase
				"007"
			when "General".downcase
				"007"
			when "Pirelli".downcase
				"008"
			when "Hankook".downcase
				"042"
			when "Riken".downcase
				"046"
			when "Greenball".downcase
				"047"
			when "Maxxis".downcase
				"126"
			when "Omni".downcase
				"124"
			else
				""
		end
	end

	def get_manu_name_from_tci_vendor_no(vendor_no)
		case vendor_no.to_i
			when 1
				["BFGoodrich"]
			when 2
				["Trivant"]
			when 3
				["Michelin"]
			when 4
				["Yokohama"]
			when 5
				["Uniroyal"]
			when 7
				["Continental", "General"]
			when 8
			 	["Pirelli"]
			when 42
				["Hankook"]
			when 46
				["Riken"]
			when 47
				["Greenball"]
			when 126
				["Maxxis"]
			when 124
				["Omni"]
			else
				[]
		end
	end

	def get_th_manu_id_from_tci_vendor_no(vendor_no)
		result = []

		ar = get_manu_name_from_tci_vendor_no(vendor_no)
		ar.each do |manu_name|
			manu = TireManufacturer.find_by_name(manu_name)
			if !manu.nil?
				result << manu.id
			end
		end

		return result
	end

	def search_size(dist, username, password, sizestr, found_models, not_found_models, tire_listings, tire_store, tire_manufacturer_ids)
		sizestr = get_searchsize(sizestr)
        client = Savon.client(wsdl: "http://www.tcitips.com/Websales/cfc/TCi_SearchSizeTIPS.cfc?wsdl")
        response = client.call :search_by_size, 
                                :message => { 
                                    param_User: username,
                                    param_Pass: password,
                                    param_Size: sizestr#,
                                    #param_Brand: 7
                                    #param_QuoteBack: ''
                                }
        doc = REXML::Document.new(response.to_xml.to_s)
        #puts "*** DOC: #{doc}"
        doc.elements.each('//tire') do |tire|
            #puts "***TIRE IS A #{tire.class}"
            tciPN = tire.get_elements('tciPN').first.text
            manuPN = tire.get_elements('manuPN').first.text
            vendor = tire.get_elements('vendor').first.text
            price = tire.get_elements('tipsmainprice').first.text
            qty = tire.get_elements('invqty').first.text.to_i

            manus = get_th_manu_id_from_tci_vendor_no(vendor)

            tmp_found_models = []

            if !manuPN.nil?
	            manus.each do |manu_id|
	            	if tire_manufacturer_ids.include?(manu_id)
		            	tm = TireModel.find_by_tire_manufacturer_id_and_product_code(manu_id, manuPN)

		            	# some of the Pirelli models start with three zeros on the TCI site, but our
		            	# database doesn't have them.
		            	tm = TireModel.find_by_tire_manufacturer_id_and_product_code(manu_id, manuPN.sub(/^000/, '')) if tm.nil?

		            	if !tm.nil?
		            		tmp_found_models << tm

		            		# 9/24/14 ksi
		            		if !tciPN.blank?
		            			old_pn = tm.get_sku_for_tire_distributor_id(dist.id)
		            			if old_pn != tciPN
		            				tm.set_sku_for_tire_distributor_id(dist.id, tciPN)
		            				tm.save
		            			end
		            		end

		            		# now, do we have or need to create a new listing for this store?
		            		tl = TireListing.find_by_tire_store_id_and_tire_model_id_and_is_new(tire_store.id, tm.id, true)
		            		if !tl
		            			tl = TireListing.new
		            			tl.tire_store_id = tire_store.id
		            			tl.tire_model_id = tm.id
		            			tl.tire_manufacturer_id = tm.tire_manufacturer_id
		            			tl.tire_size_id = tm.tire_size_id
		            			tl.is_new = true
		            		end

		            		tl.source = "TCI API import" if tl.source != "TCI API import"
		            		tl.quantity = [4, qty].min if tl.quantity != [4, qty].min
		            		tl.price = price if tl.price != price

		            		tire_listings << tl
		            	end
		            end
	            end

	            if tmp_found_models.size == 0
	            	tmp = []
	            	tmp << manuPN #<< tciPN
	            	not_found_models[vendor] = [] if not_found_models[vendor].nil?
	            	not_found_models[vendor] << tmp
	            else
	            	tmp_found_models.each do |tm|
	            		found_models << tm
	            	end
	            end
            end
        end
	end

	def import_tire_store_data(tire_store)
		log = []
		start_time = Time.now

		@tci = Distributor.find_by_distributor_name_and_city('Tire Centers, LLC', 'Norcross')
		if @tci
			@xref_rec = TireStoresDistributor.find_by_tire_store_id_and_distributor_id(tire_store.id, @tci.id)
			if @xref_rec
				# now we're ready to scrape
				not_found_models = {}
				found_models = []
				tire_listings = []

				TireSize.find(:all).each do |size|
				#TireSize.find_all_by_sizestr('205/55R16').each do |size|
					search_size(@tci, @xref_rec.username, @xref_rec.decrypted_password, size.sizestr, found_models, not_found_models, tire_listings, tire_store, @xref_rec.tire_manufacturers_list.map{|m| m.id})
				end
				records_created = 0
				records_updated = 0
				records_untouched = 0
				records_deleted = 0

				bench = Benchmark.measure {

					tire_listings.each do |t|
						if t.new_record?
							records_created += 1
							t.save
						elsif t.changed?
							records_updated += 1
							log << "#{t.tire_size.sizestr} #{t.tire_manufacturer.name} #{t.tire_model.name} #{t.quantity} #{t.price}"
							t.changes.each do |c|
								log << "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Changed #{c.first} from #{c.last.first.to_s} to #{c.last.last.to_s}"
							end
							t.save
						else
							records_untouched += 1
						end
					end
				}

				log << ""
				log << "Summary:"
				log << "New records:       #{records_created}"
				log << "Modified records:  #{records_updated}"
				log << "Untouched records: #{records_untouched}"

				log << ""
				log << bench

				@xref_rec.records_created = records_created
				@xref_rec.records_updated = records_updated
				@xref_rec.records_untouched = records_untouched
				@xref_rec.records_deleted = records_deleted
				@xref_rec.last_run_time = Time.now
				@xref_rec.save

				# email
				c = ContactUs.new(:sender_name => 'TreadHunter Report',
									:email => 'mail@treadhunter.com',
									:support_type => 'Batch Report',
									:content => log.join("<br>"))
				c.save
			end
		end
	end

	def test_order(tire_store, tire_model, qty)
		@tci = Distributor.find_by_distributor_name_and_city('Tire Centers, LLC', 'Norcross')
		if @tci
			@xref_rec = TireStoresDistributor.find_by_tire_store_id_and_distributor_id(tire_store.id, @tci.id)
			if @xref_rec
        		client = Savon.client(wsdl: "http://www.tcitips.com/Websales/cfc/TCi_PlaceOrder.cfc?wsdl")
        		response = client.call :checkout, 
                                :message => { 
                                    param_user: username,
                                    param_pass: password,
                                    param_order: sizestr#,
                                    #param_Brand: 7
                                    #param_QuoteBack: ''
                                }
        		doc = REXML::Document.new(response.to_xml.to_s)
        		#puts "*** DOC: #{doc}"
        		doc.elements.each('//tire') do |tire|
        		end
			end
		end		
	end

	def realtime_price_quote(tire_store_id, tire_model_id)
		begin
			@tci = Distributor.find_by_distributor_name_and_city('Tire Centers, LLC', 'Norcross')
			@tire_store = TireStore.find(tire_store_id)
			@xref_rec = TireStoresDistributor.find_by_tire_store_id_and_distributor_id(@tire_store.id, @tci.id)
			@tire_model = TireModel.find(tire_model_id)

			@price_quote = PriceQuote.new

			if @tci && @tire_store && @xref_rec && @tire_model
				sku = @tire_model.get_sku_for_tire_distributor_id(@tci.id)
				if sku
					xml = "<Search><tires><tire partnum='#{sku}'/></tires></Search>"
			        client = Savon.client(wsdl: "http://www.tcitips.com/Websales/cfc/TCi_SearchSKUTIPS.cfc?wsdl")
			        response = client.call :search_by_sku, 
			                                :message => { 
			                                    param_User: @xref_rec.username,
			                                    param_Pass: @xref_rec.decrypted_password,
			                                    param_SKU: xml
			                                }
			        doc = REXML::Document.new(response.to_xml.to_s)
			        #puts "*** DOC: #{doc}"
			        doc.elements.each('//tire') do |tire|
  						@price_quote.description = tire.get_elements('description').first.text unless tire.get_elements('description').nil?
  						@price_quote.tci_part_no = tire.get_elements('tciPN').first.text unless tire.get_elements('tciPN').nil?
  						@price_quote.manu_part_no = tire.get_elements('manuPN').first.text unless tire.get_elements('manuPN').nil?
			        	@price_quote.price = tire.get_elements('price').first.text unless tire.get_elements('price').nil?
			        	@price_quote.inv_qty = tire.get_elements('invqty').first.text.to_i unless tire.get_elements('invqty').nil?
			        	@price_quote.tips_main_price = tire.get_elements('tipsmainprice').first.text unless tire.get_elements('tipsmainprice').nil?
						@price_quote.tips_disc_price = tire.get_elements('tipsdiscprice').first.text unless tire.get_elements('tipsdiscprice').nil?
						@price_quote.fet = tire.get_elements('fet').first.text unless tire.get_elements('fet').nil?
						@price_quote.vendor = tire.get_elements('vendor').first.text unless tire.get_elements('vendor').nil?
			        end

			        doc.elements.each('//specs') do |spec|
			        	@price_quote.format_size = spec.get_elements('formatSize').first.text unless spec.get_elements('formatSize').nil?
			        	@price_quote.service_description = spec.get_elements('servDesc').first.text unless spec.get_elements('servDesc').nil?
			        	@price_quote.sidewall = spec.get_elements('sideWall').first.text unless spec.get_elements('sideWall').nil?
			        	@price_quote.rim_width = spec.get_elements('rimWidth').first.text unless spec.get_elements('rimWidth').nil?
			        	@price_quote.sec_width = spec.get_elements('secWidth').first.text unless spec.get_elements('secWidth').nil?
			        	@price_quote.diameter = spec.get_elements('diam').first.text unless spec.get_elements('diam').nil?
			        	@price_quote.tread_depth = spec.get_elements('treadDepth').first.text unless spec.get_elements('treadDepth').nil?
			        	@price_quote.max_single = spec.get_elements('maxSing').first.text unless spec.get_elements('maxSing').nil?
			        	@price_quote.max_dual = spec.get_elements('maxDual').first.text unless spec.get_elements('maxDual').nil?
			        	@price_quote.utqg_treadwear = spec.get_elements('treadwear').first.text unless spec.get_elements('treadwear').nil?
			        	@price_quote.utqg_traction = spec.get_elements('traction').first.text unless spec.get_elements('traction').nil?
			        	@price_quote.utqg_temp = spec.get_elements('temperature').first.text unless spec.get_elements('temperature').nil?
			        end

			        doc.elements.each('//imgs') do |img|
			        	@price_quote.img_small = img.get_elements('halfSmall').first.text unless img.get_elements('halfSmall').nil?
			        	@price_quote.img_large = img.get_elements('large').first.text unless img.get_elements('large').nil?
			        end

			        return @price_quote
				else
					return nil
				end
			else
				return nil
			end
		rescue Exception => e
			puts e.to_s
			return nil
		end
	end

	def test
		puts Benchmark.measure {
			not_found_models = {}
			found_models = []
			tire_listings = []
			#TireSize.find(:all).each do |size|
			TireSize.find_all_by_sizestr('205/55R16').each do |size|
				search_size('4330167', 'd73nfsyd', size.sizestr, found_models, not_found_models, tire_listings, TireStore.first)
			end

			system 'clear'
			puts "**** NOT FOUND ****"
			not_found_models.each do |k,v|
				puts ""
				puts "------"
				puts "#{k} (#{get_manu_name_from_tci_vendor_no(k).first}) (#{v.count})"
				puts "------"
				puts v.join("/")
			end
			puts ""
			puts "**** FOUND ****"
			puts "#{found_models.count}"

			puts "#{tire_listings.count} listings!!!"
		}
	end
end