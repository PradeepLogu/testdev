require 'thread/pool'

class TireStoresDistributor < ActiveRecord::Base
	attr_accessible :tire_store_id, :distributor_id
	attr_accessible :frequency_days, :next_run_time, :last_run_time
	attr_accessible :records_created, :records_updated, :records_untouched, :records_deleted
	### attr_accessible :password, :password_confirmation,
	attr_accessible :username, :password_digest
	attr_accessor :password, :password_confirmation

	after_initialize :init
	before_save :calculate_next_run_time
	after_save :encrypt_password

	validates_presence_of :tire_store_id, :distributor_id, :username
	validates :frequency_days, :numericality => true, :inclusion => { :in => [0, 30, 60, 90] }

  	validates_confirmation_of :password

  	belongs_to :tire_store

  	belongs_to :distributor

	serialize :tire_manufacturers, ActiveRecord::Coders::Hstore

	# has_secure_password

	def secret_key
		Digest::SHA256.hexdigest(self.created_at.to_s)
	end

	def init
		self.frequency_days ||= 30
		self.last_run_time = Time.now - 1.days
		self.next_run_time = self.last_run_time
	end

	def encrypt_password
		if !self.password.nil? && !self.password_confirmation.nil?
			if self.password == self.password_confirmation && self.password.length > 0
				self.update_column(:password_digest, Base64.encode64(Encryptor.encrypt(self.password, :key => secret_key)))
			end
		end
	end

	def decrypted_password
		begin
			Encryptor.decrypt(Base64.decode64(self.password_digest), :key => secret_key)
		rescue
			""
		end
	end

	def tire_manufacturers_list
		result = []
		self.tire_manufacturers.keys.each do |k|
			if self.tire_manufacturers[k] == "tire_manufacturer_id"
				result << TireManufacturer.find(k)
			end
		end
		result
	end	

	def add_tire_manufacturer_id(tire_manufacturer_id)
		self.tire_manufacturers = {} if self.tire_manufacturers == ""
		self.tire_manufacturers = (tire_manufacturers || {}).merge(tire_manufacturer_id.to_s => "tire_manufacturer_id")
	end

	def remove_tire_manufacturer_id(tire_manufacturer_id)
		self.tire_manufacturers = {} if self.tire_manufacturers == ""
		self.tire_manufacturers = self.tire_manufacturers.except(tire_manufacturer_id.to_s)
	end

	def calculate_next_run_time
		if self.next_run_time <= Time.now && self.last_run_time < Time.now && self.frequency_days >= 30
			self.next_run_time = self.last_run_time + self.frequency_days.days
		end
	end

	def import_markup_info_from_tci(overwrite_existing_markups = false)
		# first, check to see if we are a TCI record
		tci_name = Distributor.tci_distributor_name

		system_error_msg = "There was a system error importing markup data from TCI - we will fix this and try again shortly."
		if self.distributor.distributor_name.downcase != tci_name.downcase
			message = "TireStoresDistributor record id: #{self.id} - trying to run import_markup_info_from_tci but my distributor name is #{self.distributor.distributor_name}, not #{tci_name}."

			# now create a notification for the store.
			Notification.create_error_message(self.tire_store_id, system_error_msg)

			# create a super user notification
			Notification.create_super_user_notification(message, "TCI Markup Error", 120000, Time.now + 3.days, 5, "error")

			return false, message
		end

		# now we need to see if we have a TCI warehouse that serves this store
		my_warehouse_xref = TireStoreWarehouse.find_by_tire_store_id_and_distributor_id(self.tire_store_id, self.distributor_id)
		if !my_warehouse_xref
			message = "TireStoresDistributor record id: #{self.id} - trying to run import_markup_info_from_tci but there is no TCI Warehouse for #{self.tire_store_id}"

			# now create a notification for the store.
			Notification.create_error_message(self.tire_store_id, system_error_msg)

			# create a super user notification
			Notification.create_super_user_notification(message, "TCI Markup Error", 120000, Time.now + 3.days, 5, "error")

			return false, message
		end

		my_warehouse = Warehouse.find(my_warehouse_xref.warehouse_id)

		tci = TCIInterface.new

		manu_hash = {}

		if Rails.env.production?
			pool = Thread.pool(4)
		elsif Rails.env.staging?
			pool = Thread.pool(2)
		else
			pool = Thread.pool(8)
		end

		total_tire_models_found = 0
		total_tire_models_not_found = 0
		total_timeouts = 0

		email_log = []

		TireSize.find(:all).each do |size|
        	#pool.process {
				search_size = size.sizestr.scan(/(\d*)\/*(\d*)R*(\d*)/).join('')
				#puts search_size

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
	 				total_timeouts += 1
	 				break
	 			end
		        doc = REXML::Document.new(response.to_xml.to_s)
		        #puts "*** DOC: #{doc}"
		        num_tires = 0
		        doc.elements.each('//tire') do |tire|
		        	num_tires += 1
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
				            		total_tire_models_found += 1

				            		markup_pct = (((tipsmainprice.to_f / price.to_f) - 1).round(2)) * 100

				            		# ok now we need to add to our hash table of manufacturers/markup percentage
				            		manu_markups = manu_hash[tm.tire_manufacturer.name] || (manu_hash[tm.tire_manufacturer.name] = {})

				            		# now look in the markups for our percentage
				            		pct_array = manu_markups[markup_pct] || (manu_markups[markup_pct] = [])

				            		pct_array << tm
				            	else
				            		total_tire_models_not_found += 1
				            	end
				            else
				            	email_log << "err: Tire manu ids (#{tire_manufacturer_ids}) does not include #{manu_id}"
				            	total_tire_models_not_found += 1
				            end
						end
					else
						#email_log << "err: For #{tciPN}, the manu part num is nil."
						#email_log << doc
					end
	        	end
				#email_log << "Size: #{size.sizestr} had #{num_tires} tires."
	        #}
		end

		pool.shutdown

		if total_timeouts != 0
			email_log << "We had #{total_timeouts} processing data."
		end
		email_log << "Total tire models found and processed: #{total_tire_models_found}"
		email_log << "Total tire models not found: #{total_tire_models_not_found}"
		email_log << ""

		# now look at our hash
		manu_hash.each do |k1, v1|
			# k1 is manu name, v1 is another hash of percentages
			most_used_markup = {}
			i = 0
			v1.each do |k2, v2|
				# k2 is the markup percentage, v2 is the array of tire models
				# puts "#{k1} - #{k2} (#{v2.size})"
				# email_log << "i is #{i}, there are #{v1.size} total percentage hashes"
				# puts "i is #{i}, there are #{v1.size} total percentage hashes"
				if i == 0
					most_used_markup = {k2 => v2}
				elsif v2.size > most_used_markup.values.first.size
					# this becomes our most used markup for this manufacturer...
					most_used_markup = {k2 => v2}
				end
				i+=1
			end

			# now we have our most used markup for this manufacturer.
			tire_manu = TireManufacturer.find_by_name(k1)

			if !tire_manu
				email_log << "Something goofy here...we could not find a tire manufacturer named #{k1}."
			else
				existing_manu_markup = TireStoreMarkup.find_by_tire_store_id_and_warehouse_id_and_tire_manufacturer_id_and_markup_type(self.tire_store_id, my_warehouse.id, tire_manu.id, 0)
				if existing_manu_markup
					# we already have a markup for this manufacturer.  let's see if it matches.
					if '%.2f' % existing_manu_markup.markup_pct != '%.2f' % most_used_markup.keys.first
						email_log << "Our analysis of #{k1} shows the most common markup is #{'%.2f' % most_used_markup.keys.first}%,"
						email_log << "but you already had a markup saved at #{'%.2f' % existing_manu_markup.markup_pct}."
						if overwrite_existing_markups
							email_log << "You indicated that we should overwrite any existing markups with the TCI markups, so"
							email_log << "we are changing the markup for #{k1} from #{'%.2f' % existing_manu_markup.markup_pct} to #{'%.2f' % most_used_markup.keys.first}."
							existing_manu_markup.markup_pct = most_used_markup.keys.first 
							existing_manu_markup.save
						else
							email_log << "You indicated that we should NOT overwrite any existing markups with the TCI markups, so"
							email_log << "we will leave the markup as-is and add any non-standard markups from TCI."
						end
					else
						email_log << "Our analysis of #{k1} shows the most common markup is #{'%.2f' % most_used_markup.keys.first}%,"
						email_log << "and it is already set that way so we will leave the markup as-is and add any non-standard markups from TCI."
					end
				else
					existing_manu_markup = TireStoreMarkup.new
					existing_manu_markup.tire_store_id = self.tire_store_id 
					existing_manu_markup.warehouse_id = my_warehouse.id 
					existing_manu_markup.tire_manufacturer_id = tire_manu.id 
					existing_manu_markup.markup_type = 0
					existing_manu_markup.markup_pct = most_used_markup.keys.first.to_f
					existing_manu_markup.save

					email_log << "There was not an existing markup record for #{k1}, so we created one using the most common TCI markup of #{'%.2f' % most_used_markup.keys.first}"
				end

				untouched = 0
				v1.each do |k2, v2|
					#k2 is the markup, v2 is the array of tire models
					if '%.2f' % k2 != '%.2f' % existing_manu_markup.markup_pct
						v2.each do |tm|
							email_log << "     - creating markup of #{'%.2f' % k2}% for #{tm.description}"
							new_markup = TireStoreMarkup.new
							new_markup.tire_store_id = self.tire_store_id 
							new_markup.warehouse_id = my_warehouse.id 
							new_markup.tire_model_id = tm.id
							new_markup.markup_type = 0
							new_markup.markup_pct = k2.to_f
							new_markup.save
						end
					else
						untouched += 1
					end
				end
				email_log << "Special #{k1} markups left alone: #{untouched}"
			end
			email_log << "---------------------------------------------------------------"
		end

		ActionMailer::Base.delay.mail(:from => "mail@treadhunter.com", 
			:to => self.tire_store.contact_email, 
			:cc => system_process_completion_email_address(), 
			:subject => "Imported TCI markup data", 
			:body => email_log.join("\n"))
	end


	def import_my_tier_pricing_from_tci()
		# first, check to see if we are a TCI record
		tci_name = Distributor.tci_distributor_name

		email_log = []

		if self.distributor.distributor_name.downcase != tci_name.downcase
			message = "TireStoresDistributor record id: #{self.id} - trying to run import_my_tier_pricing_from_tci but my distributor name is #{self.distributor.distributor_name}, not #{tci_name}."

			# create a super user notification
			Notification.create_super_user_notification(message, "TCI Pricing Import Error", 120000, Time.now + 3.days, 5, "error")

			return false, message
		end

		# now we need to see if we have a TCI warehouse that serves this store
		my_warehouse_xref = TireStoreWarehouse.find_by_tire_store_id_and_distributor_id(self.tire_store_id, self.distributor_id)
		if !my_warehouse_xref
			message = "TireStoresDistributor record id: #{self.id} - trying to run import_my_tier_pricing_from_tci but there is no tire store/distributor xref for #{self.tire_store_id} and #{self.distributor_id}"

			# create a super user notification
			Notification.create_super_user_notification(message, "TCI Pricing Import Error", 120000, Time.now + 3.days, 5, "error")

			return false, message
		end

		my_warehouse = Warehouse.find_by_id(my_warehouse_xref.warehouse_id)
		if !my_warehouse
			message = "TireStoresDistributor record id: #{self.id} - trying to run import_my_tier_pricing_from_tci but there is no TCI Warehouse with ID=#{my_warehouse_xref.warehouse_id}"

			# create a super user notification
			Notification.create_super_user_notification(message, "TCI Pricing Import Error", 120000, Time.now + 3.days, 5, "error")

			return false, message
		end

		my_warehouse_tier_xref = TireStoreWarehouseTier.find_by_tire_store_id_and_warehouse_id(self.tire_store_id, my_warehouse.id)
		if !my_warehouse_tier_xref
			message = "TireStoresDistributor record id: #{self.id} - trying to run import_my_tier_pricing_from_tci but there is no TCI Warehouse Tier XREF with store_id=#{self.tire_store_id} and warehouse_id=#{my_warehouse.id}"

			# create a super user notification
			Notification.create_super_user_notification(message, "TCI Pricing Import Error", 120000, Time.now + 3.days, 5, "error")

			return false, message
		end

		my_warehouse_tier = WarehouseTier.find_by_id(my_warehouse_tier_xref.warehouse_tier_id)
		if !my_warehouse_tier
			message = "TireStoresDistributor record id: #{self.id} - trying to run import_my_tier_pricing_from_tci but there is no TCI Warehouse Tier with id = #{my_warehouse_tier_xref.warehouse_tier_id}"

			# create a super user notification
			Notification.create_super_user_notification(message, "TCI Pricing Import Error", 120000, Time.now + 3.days, 5, "error")

			return false, message
		end

		email_log << "Importing TCI pricing data for Warehouse=#{my_warehouse.name} (#{my_warehouse.city}, #{my_warehouse.state})"
		email_log << ""
		email_log << "Tier name is #{my_warehouse_tier.tier_name}:"

		tci = TCIInterface.new

		if Rails.env.production?
			pool = Thread.pool(1)
		elsif Rails.env.staging?
			pool = Thread.pool(1)
		else
			pool = Thread.pool(1)
		end

		total_added = 0
		total_updated = 0
		total_not_updated = 0

		TireSize.find(:all).each do |size|
        	#pool.process {
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
				            		pricing_record = WarehousePrice.find_by_warehouse_id_and_warehouse_tier_id_and_tire_model_id(my_warehouse.id, my_warehouse_tier.id, tm.id)
				            		if !pricing_record
				            			total_added += 1

				            			pricing_record = WarehousePrice.new 
				            			pricing_record.warehouse_id = my_warehouse.id 
				            			pricing_record.warehouse_tier_id = my_warehouse_tier.id 
				            			pricing_record.tire_model_id = tm.id 
				            			pricing_record.base_price_warehouse_price_id = nil 
				            			pricing_record.base_price = price
				            			pricing_record.cost_pct_from_base = 0.0
				            			pricing_record.wholesale_price = price.to_f

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
	        #}
		end

		pool.shutdown

		email_log << ""
		email_log << "Total added: #{total_added}"
		email_log << "Total updated: #{total_updated}"
		email_log << "Total not updated: #{total_not_updated}"

		ActionMailer::Base.delay.mail(:from => "mail@treadhunter.com", 
			:to => system_process_completion_email_address(), 
			:subject => "Imported TCI tier pricing data", 
			:body => email_log.join("\n"))

		# now update all this warehouse's customers with the new prices
		my_warehouse_tier.update_customer_prices
	end
end