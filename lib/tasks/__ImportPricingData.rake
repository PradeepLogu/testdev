require 'nokogiri'
require 'open-uri'
require 'openssl'
require 'geokit'
require 'restclient'
require "capybara"
require "capybara-webkit"
require "zip"


def ReadPricingData(url, bEncode = true)
	url = URI::encode(url) if bEncode
	result = ""
	(1..5).each do |i|
		begin
			result = RestClient.get url, :user_agent => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) "
			break
		rescue Interrupt => e
			result = "INTERRUPT"   			
		rescue Exception => e 
			puts "Exception: #{e.to_s}"
			result = ""
		end
	end
	return result
end


def ReadTireRackPricingData(url)
	url = URI::encode(url)
	result = ""
	(1..5).each do |i|
		begin
			result = RestClient.get url, :user_agent => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) ", :cookies => {"DESKTOP.TIRERACK.COM-172.16.1.43-COOKIE"=>"R2559746321", "JSESSIONID"=>"755986ED18E49C064518243A68409254"}
			break
		rescue Interrupt => e
			result = "INTERRUPT"   			
		rescue Exception => e 
			puts "Exception: #{e.to_s}"
			result = ""
		end
	end
	return result
end

def GetGoodyearProductCodeForUnavailableItem(sURL)
	prod_response = ReadPricingData(sURL)
	if prod_response == "INTERRUPT"
		return nil 
	elsif !prod_response.to_s.blank?
		prod_data = Nokogiri::HTML(prod_response.to_s)
		puts prod_data
		result = prod_data.xpath("//div[@class='specs-table']/span[.='Product Code']/following-sibling::span[1]").text()
		puts "Returning #{result}"
		return result
	end
end

namespace :ImportPricingData do
	desc "Import MSRP Pricing data from Goodyear"
	task goodyear_msrp: :environment do
		encoding_options = {
			:invalid           => :replace,  # Replace invalid byte sequences
			:undef             => :replace,  # Replace anything not defined in ASCII
			:replace           => '',        # Use a blank for those replacements
			:universal_newline => true       # Always break lines with \n
		}		
		tire_manu = TireManufacturer.find_by_name("Goodyear")
		TireSize.all.each do |t|
			puts "processing #{t.sizestr}"
			goodyear_url = "https://www.goodyear.com/en-US/tire/search/#{t.diameter}_#{t.ratio}_#{t.wheeldiameter.to_i}"
			main_response = ReadPricingData(goodyear_url)

			if main_response == "INTERRUPT"
				break
			elsif !main_response.to_s.blank?
				main_data = Nokogiri::HTML(main_response.to_s)

				if false
					main_data.xpath("//div[contains(@class,'tire-baseballcard fits Goodyear')]").each do |tire_info| 
						name = ActionView::Base.full_sanitizer.sanitize(tire_info.xpath(".//meta[@itemprop='name']").attr("content").text().encode(Encoding.find('ASCII'), encoding_options)).gsub(/^Goodyear/, '')

						price = tire_info.xpath(".//span[@class='price']").first.text()
						product_num_node = tire_info.xpath(".//input[@name='productCodePost']").first
						if product_num_node
							product_num_raw = product_num_node.attr('value')
							product_num = product_num_raw.match(/prod\-line\-\d\d\-(\d*)/)[0]

							puts "looked, found: #{product_num}"
						else
	    	    			# we have to drill into the page...
	    	    			sURL = tire_info.xpath(".//a[@class='link-chevron']").attr("href")
	    	    			product_num = GetGoodyearProductCodeForUnavailableItem("http://www.goodyear.com#{sURL}")
	    	    			if product_num == "INTERRUPT"
	    	    				break
	    	    			end
	    	    		end

	    	    		puts "Name: #{name}"
	    	    		puts "Price: #{price}"
	    	    		puts "Product: #{product_num}"
	    	    	end
	    	    else 
	    	    	# strip off the first part
	    	    	main_data = main_data.to_s.gsub(/.*?jsonObjects\.trackingContext.*?\=/m, '')
	    	    	# now strip off the last part
	    	    	main_data = main_data.gsub(/window.jsonObjects.*/m, '').gsub(/\}\;/, '}').strip()
	    	    	my_hash = JSON.parse(main_data)
	    	    	my_hash["tires"].each do |h|
	    	    		tire_model = TireModel.find_by_tire_manufacturer_id_and_manu_part_num(tire_manu.id, h["productCode"])
	    	    		if tire_model.nil?
	    	    			# puts "**** COULD NOT FIND #{h['name']} - #{h['productCode']}"
	    	    		else
	    	    			puts "Name: " + h["name"]
	    	    			puts "Price: " + h["price"]
	    	    			puts "Product Code: " + h["productCode"]
	    	    			puts "TH name: " + tire_model.name
	    	    			puts "--------------------------------------------"

	    	    			tmp = TireModelPricing.find_or_create_by_tire_model_id_and_price_type_and_source(tire_model.id, "msrp", "Goodyear.com")
	    	    			tmp.orig_source = "Goodyear.com"
	    	    			tmp.source_url = goodyear_url
	    	    			tmp.tire_ea_price = h["price"].to_f
	    	    			tmp.save
	    	    		end
	    	    	end
	    	    end
	    	end
	    end
	end


	desc "Import MSRP Pricing data from Dunlop"
	task dunlop_msrp: :environment do
		encoding_options = {
			:invalid           => :replace,  # Replace invalid byte sequences
			:undef             => :replace,  # Replace anything not defined in ASCII
			:replace           => '',        # Use a blank for those replacements
			:universal_newline => true       # Always break lines with \n
		}		
		tire_manu = TireManufacturer.find_by_name("Dunlop")
		TireSize.all.each do |t|
			puts "processing #{t.sizestr}"
			dunlop_url = "http://www.dunloptires.com/en-US/tires/search/#{t.diameter}_#{t.ratio}_#{t.wheeldiameter.to_i}"
			main_response = ReadPricingData(dunlop_url)

			if main_response == "INTERRUPT"
				break
			elsif !main_response.to_s.blank?
				main_data = Nokogiri::HTML(main_response.to_s)

    	    	# stripe off the first part
    	    	main_data = main_data.to_s.gsub(/.*?jsonObjects\.tireResultList.*?\=/m, '')
    	    	# now strip off the last part
    	    	main_data = main_data.gsub(/\<\/script\>.*/m, '').gsub(/\]\;/, ']').strip()
    	    	my_hash = JSON.parse(main_data)
    	    	my_hash.each do |tire_info|
    	    		product_num = tire_info["inventoryItem"]["productCode"].gsub(/00000$/, '')
    	    		price = tire_info["inventoryItem"]["msrp"]["price"]
    	    		name = ActionView::Base.full_sanitizer.sanitize(tire_info["name"]).encode(Encoding.find('ASCII'), encoding_options).gsub(/\&reg\;/, '').gsub(/\&trade\;/, '')
    	    		tire_model = TireModel.find_by_tire_manufacturer_id_and_manu_part_num(tire_manu.id, product_num)
    	    		if tire_model.nil?
    	    			## puts "**** COULD NOT FIND #{name} - #{product_num}"
    	    		else
    	    			puts "Name: " + name
    	    			puts "Price: " + price.to_s
    	    			puts "Product Code: " + product_num
    	    			puts "TH name: " + tire_model.name
    	    			puts "--------------------------------------------"

    	    			tmp = TireModelPricing.find_or_create_by_tire_model_id_and_price_type_and_source(tire_model.id, "msrp", "Dunlop.com")
    	    			tmp.orig_source = "Dunlop.com"
    	    			tmp.source_url = dunlop_url
    	    			tmp.tire_ea_price = price
    	    			tmp.save
    	    		end
    	    	end
    	    end
    	end	
    end


    desc "Import MSRP Pricing data from Michelin"
    task michelin_msrp: :environment do
    	encoding_options = {
			:invalid           => :replace,  # Replace invalid byte sequences
			:undef             => :replace,  # Replace anything not defined in ASCII
			:replace           => '',        # Use a blank for those replacements
			:universal_newline => true       # Always break lines with \n
		}		
		tire_manu = TireManufacturer.find_by_name("Michelin")
		TireSize.all.each do |t|
			puts "processing #{t.sizestr}"
			michelin_url = "http://www.michelinman.com/US/en/tires/#{t.diameter}/#{t.ratio}/#{t.wheeldiameter.to_i}.html"
			main_response = ReadPricingData(michelin_url)

			if main_response == "INTERRUPT"
				break
			elsif !main_response.to_s.blank?
				main_data = Nokogiri::HTML(main_response.to_s)
				main_data.xpath("//div[contains(@class,'productdetailpage')]").each do |tire_info|
					sku_list = tire_info.xpath(".//div[contains(@class, 'search-result-main')]").attr('data-sku')
					my_hash = JSON.parse(sku_list)
					name = ActionView::Base.full_sanitizer.sanitize(tire_info.xpath(".//h3[@itemprop='name']").first.text().strip()).encode(Encoding.find('ASCII'), encoding_options)
					if my_hash["exactmatchTires"].size == 1
						# there is only one tire, so the displayed price is the right one.
						price = tire_info.xpath(".//div[@class='price']/span[@class='important']").text().gsub(/\D/, '')
						product_num = my_hash["lsku"][0].gsub(/Michelin\-US\-/, '')

						tire_model = TireModel.find_by_tire_size_id_and_tire_manufacturer_id_and_manu_part_num(t.id, tire_manu.id, product_num)
						if tire_model && price.to_f != 0.00
							#puts "     TireModel OK"
							puts "Price is #{price}"
							puts "Name is #{name}"
							puts "--------------------------------------------------------"							
							tmp = TireModelPricing.find_or_create_by_tire_model_id_and_price_type_and_source(tire_model.id, "msrp", "MichelinMan.com")
							tmp.orig_source = "MichelinMan.com"
							tmp.source_url = michelin_url
							tmp.tire_ea_price = price.to_f
							tmp.save							
						else
							#puts "     ****  BAD TIRE MODEL #{product_num}"
						end
					else
						# there are multiple - gotta drill in...
						prod_url = "http://www.michelinman.com" + tire_info.xpath(".//a/h3[@itemprop='name']/..").attr("href")
						prod_url = prod_url.gsub(/\.html$/, '/details.ajax.html')
						prod_response = ReadPricingData(prod_url)
						if prod_response == "INTERRUPT"
							break
						elsif !prod_response.to_s.blank?
							prod_data = Nokogiri::HTML(prod_response.to_s)
							prod_data.xpath("//table[@data-table-slide='name1']//tr[@class='even' or @class='odd']").each do |row|
								raw_size = row.xpath("td[1]").text()
								price = row.xpath("td[3]").text().gsub(/\$/, '').to_f
								if price != 0.0
									arSize = /(|P|LT|Z)(\d{3})(\ x|x|\/)(\d{2})(R|ZR)(\d{2}(\.5)*)(|\/XL|\/LL) (|\()(\d{2,3})(\D)(|\))/.match(raw_size)
									if arSize.nil?
										puts "**** Could not match #{raw_size}"
									else
										sizestr = "#{arSize[2]}/#{arSize[4]}R#{arSize[6]}"
										load_index = arSize[10]
										speed_rating = arSize[11]
										possible_speed_ratings = []
										possible_speed_ratings << speed_rating << "(#{speed_rating})"
										product_num = row.xpath("td[2]").text().strip()

										ts = TireSize.find_by_sizestr(sizestr)
										tire_model = TireModel.find_by_tire_size_id_and_tire_manufacturer_id_and_manu_part_num(ts.id, tire_manu.id, product_num)

										if tire_model 
											puts "Price is #{price}"
											puts "Name is #{name}"
											tmp = TireModelPricing.find_or_create_by_tire_model_id_and_price_type_and_source(tire_model.id, "msrp", "MichelinMan.com")
											if tmp.tire_ea_price != 0.0 && tmp.tire_ea_price != price 
												puts "*** Danger: id: #{product_num}, old price=#{tmp.price}, new price=#{price}"
											end
											tmp.orig_source = "MichelinMan.com"
											tmp.source_url = prod_url
											tmp.tire_ea_price = price
											tmp.save
											puts "--------------------------------------------------------"
										else
											puts "Could not find TireModel: #{product_num}"
										end
									end
								end
							end
						end
					end
				end
			end
		end	
	end	


	desc "Import Retail Pricing data from Walmart"
	task walmart_retail: :environment do
		walmart_manufacturers = ["Goodyear", "Michelin", "BF Goodrich", "BFGoodrich", 
			"Bridgestone", "Hankook", "Continental", 
			"Uniroyal", "Nexen", "Falken", "Dunlop", "Kumho", "Douglas",
			"Kelly", "Nitto", "Pirelli", "General"]
			tire_manufacturers = TireManufacturer.find(:all, :conditions => ["name in (?)", walmart_manufacturers])
			tire_manufacturers.each do |tire_manu|
				tire_manu.tire_models.each do |tire_model|
					if !tire_model.product_code.blank? && !tire_model.has_recent_walmart_price_record
						walmart_api_url = "http://api.walmartlabs.com/v1/search?apiKey=yu66twjnnmcvzvecvep8svh4&lsPublisherId=Treadhunter&categoryId=91083&query=#{tire_model.description}"
						prod_response = ReadPricingData(walmart_api_url)
						if prod_response == "INTERRUPT"
							break
						elsif !prod_response.to_s.blank?
							found = false
							begin
								ht = JSON.parse(prod_response.to_s)
								if ht["numItems"] > 0
									ht["items"].each do |item|
										item_desc = item["name"]
										if tire_model.seems_to_match_walmart_product_description(item_desc)
											puts "Found #{tire_model.description}"
											puts item_desc

											price = item["salePrice"]

											tmp = TireModelPricing.find_or_create_by_tire_model_id_and_price_type_and_source(tire_model.id, "retail", "Walmart.com")
											if tmp.tire_ea_price != 0.0 && tmp.tire_ea_price != price 
												puts "*** Danger: id: #{product_num}, old price=#{tmp.price}, new price=#{price}"
											end
											tmp.orig_source = "Walmart.com"
											tmp.source_url = walmart_api_url
											tmp.tire_ea_price = price
											tmp.save
											puts "--------------------------------------------------------"

											found = true 
											break
										end
									end
									if !found
										puts "Could not find #{tire_model.description}"
										puts "--------------------------------------------------------"
									end
								else
									puts "Walmart doesn't seem to carry #{tire_model.description} #{ht['numItems']} #{prod_response}"
									puts walmart_api_url
									puts "--------------------------------------------------------"
								end
							rescue Exception => e 
								puts "Exception: #{e.to_s} - skipping"
							end
						end

					sleep(0.25) # make sure we don't exceed Walmart API limits
				end
			end
		end
	end

	def process_tirerack_page(oNokogiri)
		oNokogiri.xpath("//div[contains(@class, 'prodWrapper')]").each do |tire_info|
			# name = tire_info.xpath(".//input[@name='Model']").attr('value').text().strip()
			# load_index = tire_info.xpath(".//input[@name='i1_LoadIndex']").attr('value').text().strip()
			# speed_rating = tire_info.xpath(".//input[@name='i1_SpeedRating']").attr('value').text().strip()
			price = tire_info.xpath(".//input[@id='i1_Price0']").attr('value').text().strip().to_f
		end
	end
	def process_tirerack_zipcode(zipcode, latitude, longitude)
		@width = [[215,55,17],[215,60,16],[265,70,17],[275,65,18],[225,65,17],[205,55,16],[275,60,20],[195,65,15],[275,55,20],[225,60,16],[235,75,15],[225,50,17],[245,75,16],[265,75,16],[225,75,16],[235,85,16],[245,75,17],[285,75,16],[275,70,18],[285,70,17],[265,70,18],[275,65,18],[235,80,17],[255,75,17],[275,65,20]]
		@width.each do |width|
			Capybara.run_server = false
			# Capybara.default_driver = :selenium

			@headless = Headless.new
			@headless.start
			@driver = Selenium::WebDriver.for :firefox

			Capybara.app_host = "http://www.tirerack.com"
			include Capybara::DSL
			@driver.get "/tires/TireSearchResults.jsp?width=#{width[0]}%2F&ratio=#{width[1]}&diameter=#{width[2]}&rearWidth=#{width[0]}%2F&rearRatio=#{width[1]}rearDiameter=#{width[2]}&zip-code=#{zipcode}", 
			tirerack_url = "/tires/TireSearchResults.jsp?width=#{width[0]}%2F&ratio=#{width[1]}&diameter=#{width[2]}&rearWidth=#{width[0]}%2F&rearRatio=#{width[1]}&rearDiameter=#{width[2]}&zip-code=#{zipcode}"
			sleep 2
			all_price = []
			total_record = find('#vehicleNavResultCount').text()
			total_page_mod = total_record % 10
			p "-----------"
			total_page = total_record.to_i/10
			if total_page_mod != 0
				total_page = total_page + 1
			end
			(1..total_page).each do |p|
				if total_page>1
					find(:xpath, "//a[@href='/tires/TireSearchControlServlet?action=nextPage&width=#{width[0]}%2F&ratio=#{width[1]}&diameter=#{width[2]}']").click
				end
				price = all('li span.finalPrice').map(&:text)
				all_price.concat(price).compact
			end
			(1..all_price.length).each.each_with_index do |total_results, index|
				# p tmp = TireModelPricing.create(:tire_model_id => "#{width[0]}"+"#{width[1]}"+"#{width[2]}", :price_type => "retail", :source => "Tirerack.com", :zipcode =>  zipcode)
				# tmp.longitude = longitude
				# tmp.latitude = latitude
				# tmp.zipcode = zipcode
				# tmp.orig_source = "Tirerack.com"
				# tmp.source_url = tirerack_url
				# tmp.tire_ea_price = all_price[index]
				# tmp.save
			end
		end
	end



	desc "Import Retail Pricing data from Tire Rack"
	task tirerack_retail: :environment do
		@zipcode = [10016, 30305, 60601, 75252, 98101, 90210]	
		@zipcode.each do |zip|			
			geo = Geokit::Geocoders::GoogleGeocoder.geocode(zip.to_s)
			lat = geo.lat
			lon = geo.lng
			process_tirerack_zipcode(zip , lat, lon)
		end
	end

	def close_active_window
		page.driver.browser.close  
		page.driver.browser.switch_to.window(page.driver.browser.window_handles.first)
	end

	desc "Import Retail Pricing data from Pep Boys"
	task pepboys_retail: :environment do
		TireSize.find(:all).each do |ts|
			pepboys_url = "http://www.pepboys.com/tires/size/#{ts.diameter}/#{ts.ratio}/#{ts.wheeldiameter.to_i}"
			puts pepboys_url
			prod_response = ReadPricingData(pepboys_url)
			if prod_response == "INTERRUPT"
				break
			elsif !prod_response.to_s.blank?
				prod_data = Nokogiri::HTML(prod_response.to_s)

				prod_data.xpath("//div[contains(@class, 'resultsItem')]").each do |tire_info|
					product_num = tire_info.xpath(".//ul[contains(@class, 'productDetailsList')]/li[contains(., 'Part #:')]").text().strip().gsub(/Part\ \#\:/, '').gsub(/\|/, '').strip()
					manu_name = tire_info.xpath(".//div[@class='brandLabel']").text().strip().gsub(/BF\ Goodrich/, 'BFGoodrich')
					tire_manu = TireManufacturer.find_by_name(manu_name)
					if tire_manu.nil?
						puts "Skipping #{manu_name}"
					else
						tire_model = TireModel.find_by_tire_manufacturer_id_and_manu_part_num(tire_manu.id, product_num)
						if tire_model.nil?
							puts "Could not find #{manu_name} - #{product_num}"
						else
							raw_price = tire_info.xpath(".//a[@class='needItNow']")
							if !raw_price
								puts "Couldn't find in:"
								puts tire_info
							else
								begin
									if raw_price.attr('data-price').nil?
										puts "Could not find price in: #{raw_price}"
									else
										price = raw_price.attr('data-price').text().to_f

										tmp = TireModelPricing.find_or_create_by_tire_model_id_and_price_type_and_source(tire_model.id, "retail", "Pepboys.com")
										if tmp.tire_ea_price != 0.0 && tmp.tire_ea_price != price 
											puts "*** Danger: id: #{product_num}, old price=#{tmp.price}, new price=#{price}"
										end
										tmp.orig_source = "Pepboys.com"
										tmp.source_url = pepboys_url
										tmp.tire_ea_price = price
										tmp.save
										puts "--------------------------------------------------------"
									end
								rescue Exception => e 
									puts "Exception checking #{raw_price} - #{e.to_s}"
								end
							end
						end
					end
				end
			end
		end
	end	


	def build_sears_url(tire_size, zip_code)
		"http://www.sears.com/service/search/productSearch?catalogId=12605&catgroupId=1289602424&catgroupIdPath=1020005_1289593068_1289602424&ddcZone=3&levels=Automotive_Tires+%26+Wheels_Tires&primaryPath=Automotive_Tires+%26+Wheels_Tires&searchBy=subcategory&spuZone=7&storeId=10153&tabClicked=All&zip=#{zip_code}"		
	end

	def process_sears_for_zipcode(zipcode, latitude, longitude)
		TireSize.find(:all).each_with_index do |ts, index|
			puts "Processing Size: #{ts.sizestr}"
			sears_url = build_sears_url(ts, zipcode)
			prod_response = ReadPricingData(sears_url, false)
			sleep 10
			if prod_response == "INTERRUPT"
				break
			elsif !prod_response.to_s.blank?
				json_tire_list = JSON.parse(prod_response.to_s)
				pid_array = json_tire_list["products"].map{|ht| ht["partNumber"]}
				price_response = get_pricing_data_from_sears(pid_array)
				if price_response.nil?
					puts "Failed trying to get pricing data..."
				else
					json_prices = JSON.parse(price_response)

					json_tire_list["products"].each do |tire_info|
						manu_name = translate_manu_name(tire_info["brandName"])
						manu_part_num = translate_part_num(manu_name, tire_info["mfgPartNum"])
						model_name = tire_info["name"]

						tire_manu = TireManufacturer.find_by_name(manu_name)
						if tire_manu.nil?
							puts "Could not find manufacturer #{manu_name}"
						elsif manu_part_num.blank?
							#puts "Could not process #{model_name} - no part number"
						else
							tire_model = TireModel.find_by_tire_manufacturer_id_and_manu_part_num(tire_manu.id, manu_part_num)
							if tire_model.nil?
								#puts "Could not find model: #{tire_manu.name} - #{manu_part_num} - #{model_name}"
							else
								# find price in the price list
								#puts "json_prices is #{json_prices}"
								
								price_info = json_prices[tire_info["partNumber"]]
								if price_info
									if price_info["priceDisplay"] && 
										price_info["priceDisplay"]["response"]
										price_info["priceDisplay"]["response"][0]["finalPrice"] &&
										price_info["priceDisplay"]["response"][0]["finalPrice"]["numeric"]
										
										price = price_info["priceDisplay"]["response"][0]["finalPrice"]["numeric"]
										puts "price: #{price}"
										tmp = TireModelPricing.find_or_create_by_tire_model_id_and_price_type_and_source_and_zipcode(tire_model.id, "retail", "Sears.com", zipcode)
										if tmp.tire_ea_price != 0.0 && tmp.tire_ea_price != price 
											puts "*** Danger: id: #{manu_part_num}, old price=#{tmp.tire_ea_price}, new price=#{price}"
										end
										tmp.orig_source = "Sears.com"
										tmp.source_url = sears_url[0..254]
										tmp.tire_ea_price = price
										p "-----------------"
										tmp.longitude = longitude
										tmp.latitude = latitude
										tmp.zipcode = zipcode

										tmp.save
										puts "--------------------------------------------------------"
									else
										puts "Could not find finalPrice in #{price_info}"
									end
								else
									puts "Could not find #{tire_info['partNumber']} in #{json_prices}"
								end
							end
						end
					end
				end
			end
		end
	end

	def build_sears_pricing_request(pid_array)
		request_hash = {}
		data_array = pid_array.map{|pid| Hash["pid", pid, "pidType", "NONVARIATION"]}

		request_hash["data"] = data_array
		request_hash["storeId"] = "10153"
		request_hash["zipcode"] = ""
		request_hash["priceDebug"] = "false"
		request_hash["kmartPR"] = false 
		request_hash["countryCode"] = "US"
		request_hash["currencyCode"] = "USD"

		return request_hash#.to_json
	end

	desc "Test Sears"
	task sears_test: :environment do
		pid_array = ["09569121000", "09578729000"]
		data = build_sears_pricing_request(pid_array)
		puts data.to_json
		if false
			response = RestClient.post "http://www.sears.com/service/search/price/json", data.to_json
			puts response.Code
			puts response.to_str
		elsif false
			uri = URI("http://www.sears.com/service/search/price/json")
			req = Net::HTTP::Post.new#(uri)
			req.body = data.to_json

			res = Net::HTTP.start(uri.hostname, uri.port) do |http|
				http.request(req)
			end

			puts res
		else
			uri = URI('http://www.sears.com/service/search/price/json')
			req = Net::HTTP::Post.new('http://www.sears.com/service/search/price/json')
			req.content_type = 'application/json;charset=UTF-8'
			req.add_field 'Host', 'www.sears.com'
			req.add_field 'Accept', 'application/json, text/plain, */*'
			req.add_field 'Content-Type', 'application/json;charset=UTF-8'
			#req.add_field 'Cookie', 'Cookie: affiliateCookie=Guest; _ga=GA1.2.925480399.1442859708; IntnlShip=US|USD; segment=a; ot=i1-prod-ch3-vX-; irp=0558bbfe-00d0-41fd-a4d2-6a8a5ee43e69|6%2FtocCwKohI1JLI6Plfv%2BJVzUvb4y0WGXKzDUPjKhp4%3D|G|-1039318390|0|-444838868; KI_FLAG=false; ra_id=0558bbfe-00d0-41fd-a4d2-6a8a5ee43e69%7CG%7C-1039318390; s_sso=s_r%7CY%7C; lang=en; __CT_Data=gpv=1&apv_99_www04=1; WRUID=0; sn.vi=vi||d2c22034-2e8f-4a00-94db-dc5e80d2e81b; SessionPersistence=CLIENTCONTEXT%3A%3DvisitorId%253D; stk=Sears%3A; viewItems=25; s_vi=[CS]v1|2B00934C05193FF7-4000060A8000551A[CE]; aam_tnt=seg%3D104605~1932117; aam_chango=crt%3Dsears%2Ccrt%3Dautoenthusiast; aamsears=aam%3D3; aam_criteo=crt%3Dsears; sears_offers=offers%3D1; aam_uuid=32702344149436522411589311027135953100; _br_uid_2=uid%3D7959980224259%3Av%3D11.5%3Ats%3D1442915993326%3Ahc%3D9; fsr.s=%7B%22v2%22%3A-2%2C%22v1%22%3A1%2C%22rid%22%3A%22de358f9-93994826-ec8e-4f5c-eb21f%22%2C%22c%22%3A%22http%3A%2F%2Fwww.sears.com%2Fautomotive-tires-wheels-tires%26Sears%2Fb-1289602424%22%2C%22pv%22%3A5%2C%22lc%22%3A%7B%22d3%22%3A%7B%22v%22%3A5%2C%22s%22%3Atrue%7D%7D%2C%22cd%22%3A3%2C%22sd%22%3A3%7D; RT=sl=0&ss=1442920444618&tt=0&obo=0&bcn=%2F%2F36cc2473.mpstat.us%2F&sh=&dm=www.sears.com&si=9ad260f6-c69f-4810-9344-ece2bf11187e&r=http%3A%2F%2Fwww.sears.com%2Fautomotive-tires-wheels-tires%26Sears%2Fb-1289602424%3F52faffee6db4bf92b7a2a3d74843aa6e&ul=1442922827806&hd=1442922828238; mbox=PC#1442915988464-542166.28_14#1445514830|check#true#1442922890|session#1442922829030-703195#1442924690; cust_info=%7B%22customerinfo%22%3A%7B%22userName%22%3A%22%22%2C%22isGuest%22%3Atrue%2C%22isSYWR%22%3Afalse%2C%22sywrNo%22%3A%22%22%2C%22encryptedSywrNo%22%3A%22%22%2C%22sywrPoints%22%3A0%2C%22sywrAmount%22%3A0%2C%22expiringPoints%22%3A0%2C%22expiringPointsDate%22%3Anull%2C%22expiringPointsWarn%22%3Afalse%2C%22spendingYear%22%3A0%2C%22vipLevel%22%3A%22%22%2C%22nextLevel%22%3A0%2C%22isCraftsmanClub%22%3Afalse%2C%22screenName%22%3A%22%22%2C%22avatar%22%3A%22%22%2C%22maxStatus%22%3A%22SVU%22%2C%22maxSavings%22%3A0%2C%22sessionID%22%3A%220558bbfe-00d0-41fd-a4d2-6a8a5ee43e69%22%2C%22globalID%22%3A%22-1039318390%22%2C%22memberID%22%3A%22-1039318390%22%2C%22associate%22%3Afalse%2C%22pgtToken%22%3A%22%22%2C%22displayName%22%3A%22%22%2C%22partialLogin%22%3Afalse%2C%22cartCount%22%3A0%7D%7D; s_pers=%20s_vnum%3D1600595991867%2526vn%253D2%7C1600595991867%3B%20s_fid%3D4D987F281A935DCE-1493A1553D2F0D4E%7C1506081231082%3B%20s_invisit%3Dtrue%7C1442924631089%3B%20s_depth%3D1%7C1442924631093%3B%20gpv_pn%3DAutomotive%2520%253E%2520Tires%2520%2526%2520Wheels%2520%253E%2520Tires%7C1442924631098%3B%20gev_lst%3Devent80%7C1442924631103%3B%20gpv_sc%3DAutomotive%7C1442924631108%3B%20gpv_pt%3DSubcategory%7C1442924631113%3B; s_sess=%20s_cc%3Dtrue%3B%20s_e30%3DAnonymous%3B%20s_sq%3D%3B'
			req.body = data.to_json

			res = Net::HTTP.start(uri.hostname, uri.port) do |http|
				http.request(req)
			end

			puts res
		end
	end

	def get_pricing_data_from_sears(pid_array)
		data = build_sears_pricing_request(pid_array)
		uri = URI('http://www.sears.com/service/search/price/json')
		req = Net::HTTP::Post.new('http://www.sears.com/service/search/price/json')
		req.content_type = 'application/json;charset=UTF-8'
		req.add_field 'Host', 'www.sears.com'
		req.add_field 'Accept', 'application/json, text/plain, */*'
		req.add_field 'Content-Type', 'application/json;charset=UTF-8'
		#req.add_field 'Cookie', 'Cookie: affiliateCookie=Guest; _ga=GA1.2.925480399.1442859708; IntnlShip=US|USD; segment=a; ot=i1-prod-ch3-vX-; irp=0558bbfe-00d0-41fd-a4d2-6a8a5ee43e69|6%2FtocCwKohI1JLI6Plfv%2BJVzUvb4y0WGXKzDUPjKhp4%3D|G|-1039318390|0|-444838868; KI_FLAG=false; ra_id=0558bbfe-00d0-41fd-a4d2-6a8a5ee43e69%7CG%7C-1039318390; s_sso=s_r%7CY%7C; lang=en; __CT_Data=gpv=1&apv_99_www04=1; WRUID=0; sn.vi=vi||d2c22034-2e8f-4a00-94db-dc5e80d2e81b; SessionPersistence=CLIENTCONTEXT%3A%3DvisitorId%253D; stk=Sears%3A; viewItems=25; s_vi=[CS]v1|2B00934C05193FF7-4000060A8000551A[CE]; aam_tnt=seg%3D104605~1932117; aam_chango=crt%3Dsears%2Ccrt%3Dautoenthusiast; aamsears=aam%3D3; aam_criteo=crt%3Dsears; sears_offers=offers%3D1; aam_uuid=32702344149436522411589311027135953100; _br_uid_2=uid%3D7959980224259%3Av%3D11.5%3Ats%3D1442915993326%3Ahc%3D9; fsr.s=%7B%22v2%22%3A-2%2C%22v1%22%3A1%2C%22rid%22%3A%22de358f9-93994826-ec8e-4f5c-eb21f%22%2C%22c%22%3A%22http%3A%2F%2Fwww.sears.com%2Fautomotive-tires-wheels-tires%26Sears%2Fb-1289602424%22%2C%22pv%22%3A5%2C%22lc%22%3A%7B%22d3%22%3A%7B%22v%22%3A5%2C%22s%22%3Atrue%7D%7D%2C%22cd%22%3A3%2C%22sd%22%3A3%7D; RT=sl=0&ss=1442920444618&tt=0&obo=0&bcn=%2F%2F36cc2473.mpstat.us%2F&sh=&dm=www.sears.com&si=9ad260f6-c69f-4810-9344-ece2bf11187e&r=http%3A%2F%2Fwww.sears.com%2Fautomotive-tires-wheels-tires%26Sears%2Fb-1289602424%3F52faffee6db4bf92b7a2a3d74843aa6e&ul=1442922827806&hd=1442922828238; mbox=PC#1442915988464-542166.28_14#1445514830|check#true#1442922890|session#1442922829030-703195#1442924690; cust_info=%7B%22customerinfo%22%3A%7B%22userName%22%3A%22%22%2C%22isGuest%22%3Atrue%2C%22isSYWR%22%3Afalse%2C%22sywrNo%22%3A%22%22%2C%22encryptedSywrNo%22%3A%22%22%2C%22sywrPoints%22%3A0%2C%22sywrAmount%22%3A0%2C%22expiringPoints%22%3A0%2C%22expiringPointsDate%22%3Anull%2C%22expiringPointsWarn%22%3Afalse%2C%22spendingYear%22%3A0%2C%22vipLevel%22%3A%22%22%2C%22nextLevel%22%3A0%2C%22isCraftsmanClub%22%3Afalse%2C%22screenName%22%3A%22%22%2C%22avatar%22%3A%22%22%2C%22maxStatus%22%3A%22SVU%22%2C%22maxSavings%22%3A0%2C%22sessionID%22%3A%220558bbfe-00d0-41fd-a4d2-6a8a5ee43e69%22%2C%22globalID%22%3A%22-1039318390%22%2C%22memberID%22%3A%22-1039318390%22%2C%22associate%22%3Afalse%2C%22pgtToken%22%3A%22%22%2C%22displayName%22%3A%22%22%2C%22partialLogin%22%3Afalse%2C%22cartCount%22%3A0%7D%7D; s_pers=%20s_vnum%3D1600595991867%2526vn%253D2%7C1600595991867%3B%20s_fid%3D4D987F281A935DCE-1493A1553D2F0D4E%7C1506081231082%3B%20s_invisit%3Dtrue%7C1442924631089%3B%20s_depth%3D1%7C1442924631093%3B%20gpv_pn%3DAutomotive%2520%253E%2520Tires%2520%2526%2520Wheels%2520%253E%2520Tires%7C1442924631098%3B%20gev_lst%3Devent80%7C1442924631103%3B%20gpv_sc%3DAutomotive%7C1442924631108%3B%20gpv_pt%3DSubcategory%7C1442924631113%3B; s_sess=%20s_cc%3Dtrue%3B%20s_e30%3DAnonymous%3B%20s_sq%3D%3B'
		req.body = data.to_json

		res = Net::HTTP.start(uri.hostname, uri.port) do |http|
			http.request(req)
		end

		if res.code == "200"
			return res.body
		else
			puts "Failed call: #{res.code}"
			return nil
		end
	end

	def translate_part_num(manu_name, part_num)
		if manu_name == "Michelin" 
			return part_num.rjust(5, '0')
		else
			return part_num
		end
	end

	def translate_manu_name(manu_name)
		if manu_name == "General Tire"
			return "General"
		else 
			return manu_name
		end
	end


	desc "Import Wholesale Pricing data from TCI"
	task tci_wholesale: :environment do
		tci = TCIInterface.new

		TireSize.find(:all).each do |size|
			search_size = size.sizestr.scan(/(\d*)\/*(\d*)R*(\d*)/).join('')
			puts search_size

			tire_manufacturer_ids = TireManufacturer.all.map{|m| m.id}

			#Savon.configure do |config|
			#	config.log = false
			#end			

			client = Savon.client(wsdl: "http://www.tcitips.com/Websales/cfc/TCi_SearchSizeTIPS.cfc?wsdl",
				logger: Rails.logger)
			response = client.call :search_by_size, 
			:message => { 
				param_User: '4330167',
				param_Pass: 'd73nfsyd',
	                                    param_Size: search_size#,
	                                    #param_Brand: 7
	                                    #param_QuoteBack: '',
	                                }
	                                doc = REXML::Document.new(response.to_xml.to_s)
	        #puts "*** DOC: #{doc}"
	        doc.elements.each('//tire') do |tire|
	            #puts "***TIRE IS A #{tire.class}"
	            tciPN = tire.get_elements('tciPN').first.text
	            manuPN = tire.get_elements('manuPN').first.text
	            tire_vendor = tire.get_elements('vendor').first.text
	            price = tire.get_elements('tipsmainprice').first.text
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
			            		puts "#{size.sizestr} #{tm.name} - #{price}"
			            		tmp = TireModelPricing.find_or_create_by_tire_model_id_and_price_type_and_source(tm.id, "wholesale", "tcitips.com")
			            		if tmp.tire_ea_price != 0.0 && tmp.tire_ea_price != price 
			            			puts "*** Danger: id: #{tm.product_code}, old price=#{tmp.tire_ea_price}, new price=#{price}"
			            		end
			            		tmp.orig_source = "tcitips.com"
			            		tmp.source_url = "http://www.tcitips.com/Websales/cfc/TCi_SearchSizeTIPS.cfc?wsdl"
			            		tmp.tire_ea_price = price
			            		tmp.save
			            		puts "--------------------------------------------------------"		            		
			            	else
			            		puts "Could not find TireModel: #{TireManufacturer.find(manu_id).name} - #{manuPN}"
			            	end
			            end
			        end
			    end
			end
		end
	end

	desc "Analyze Pricing from TCI"
	task analyze_tci_pricing: :environment do
		tci = TCIInterface.new

		TireSize.find(:all).each do |size|
			search_size = size.sizestr.scan(/(\d*)\/*(\d*)R*(\d*)/).join('')
			#puts search_size

			tire_manufacturer_ids = TireManufacturer.all.map{|m| m.id}

			client = Savon.client(wsdl: "http://www.tcitips.com/Websales/cfc/TCi_SearchSizeTIPS.cfc?wsdl",
				logger: Rails.logger)
			response = client.call :search_by_size, 
			:message => { 
				param_User: '4330167',
				param_Pass: 'd73nfsyd',
	                                    param_Size: search_size#,
	                                    #param_Brand: 7
	                                    #param_QuoteBack: '',
	                                }
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
			            	end
			            end
			        end
			    end
			end
		end
	end

	desc "Import Retail Pricing data from Sears"
	task sears_retail: :environment do
		
		@zipcode = [10016, 30305, 60601, 75252, 98101, 90210]
		@zipcode.each do |zip|
			p geo = Geokit::Geocoders::GoogleGeocoder.geocode(zip.to_s)
			p lat = geo.lat
			p lon = geo.lng
			process_sears_for_zipcode(zip, lat, lon)
		end
	end


	desc "Import Retail Pricing data from Discount Tire"
	task discounttire_retail: :environment do
		tot_processed = 0
		tot_found = 0

		TireSize.find(:all).each do |ts|
			puts "Processing Size: #{ts.sizestr}"
			discount_tire_url = "http://www.discounttire.com/dtcs/filterTireProducts.do?pgTires=0&rcz=30092&rc=GAAINT&fl=&cs=#{ts.diameter}&ar=#{ts.ratio}&rd=#{ts.wheeldiameter.to_i}&c=0&rf=true&sortBy=prca&fqs=true"
			prod_response = ReadPricingData(discount_tire_url, false)
			if prod_response == "INTERRUPT"
				break
			elsif !prod_response.to_s.blank?
				prod_data = Nokogiri::HTML(prod_response.to_s)
				prod_data.xpath("//div[contains(@class, 'tireProductTile')]").each do |tire_info|
					tot_processed += 1
					manu_name = tire_info.xpath(".//span[@class='make']").text().strip()
					model_name = tire_info.xpath(".//span[@class='model']").text().strip()
					raw_size = tire_info.xpath(".//span[@class='tireSize']").text().strip()
					arSize = /\s*(\d{3})\s*\/(\d{2})\s*(R|ZR)(\d{2}(\.5)*)\s*(\d{2,3})(\D)(|\))/.match(raw_size)
if arSize.nil?
	puts "Could not parse #{raw_size}"
else
	load_index = arSize[6]
	speed_rating = arSize[7]
	puts "#{ts.sizestr} #{manu_name} #{model_name} #{load_index} #{speed_rating}"
	tire_manu = TireManufacturer.find_by_name(manu_name)
	if tire_manu.nil?
		puts "-- Skipping because we don't have this manufacturer"
	else
		tire_model = TireModel.find_by_tire_manufacturer_id_and_tire_size_id_and_name_and_load_index_and_speed_rating(tire_manu.id, ts.id, model_name, load_index, speed_rating)
		if tire_model.nil?
			puts "  -- Could not find model: #{tire_manu.name} - #{model_name}"
		else
			price = tire_info.xpath(".//span[@class='dollars']").text().gsub(/\$/, '').to_f
			puts "Price is #{price}"
			tot_found += 1
			tmp = TireModelPricing.find_or_create_by_tire_model_id_and_price_type_and_source(tire_model.id, "retail", "DiscountTire.com")
			if tmp.tire_ea_price != 0.0 && tmp.tire_ea_price != price 
				puts "*** Danger: #{ts.sizestr} #{manu_name} #{model_name}, old price=#{tmp.tire_ea_price}, new price=#{price}"
			end
			tmp.orig_source = "DiscountTire.com"
			tmp.source_url = discount_tire_url
			tmp.tire_ea_price = price
			tmp.save
			puts "--------------------------------------------------------"
		end
	end
end
end
end
end
puts "Able to find #{tot_found} out of #{tot_processed}."
end
def add_worksheet(manu_name, workbook)
	worksheet = workbook.add_worksheet
	return worksheet
end
desc "Put pricing info into google docs spreadsheet"
task create_pricing_spreadsheet: :environment do
	@workbook = WriteExcel.new('tire_pricing.xls')
	encoding_options = {
			:invalid           => :replace,  # Replace invalid byte sequences
			:undef             => :replace,  # Replace anything not defined in ASCII
			:replace           => '',        # Use a blank for those replacements
			:universal_newline => true       # Always break lines with \n
		}
		title_format = @workbook.add_format
		title_format.set_bold
		title_format.set_text_wrap(1)
		title_format.set_font('Arial')
		title_format.set_size(8)
		#format.set_color('red')
		#format.set_align('right')
		manu_format = @workbook.add_format
		manu_format.set_size(16)
		manu_format.set_border(0)
		std_format = @workbook.add_format
		@row_counts = []
		@worksheet_names = []
		right_border_format = @workbook.add_format
		right_border_format.set_right(6)
		tire_models_with_pricing = 0
		tire_models_without_pricing = 0
		ht_manus_without_pricing = {}
		ht_manus_with_pricing = {}
		TireModel.all.each do |tire_model|
			if tire_model.tire_model_pricings.size == 0
				tire_models_without_pricing += 1
				if ht_manus_without_pricing[tire_model.tire_manufacturer.name].nil?
					ht_manus_without_pricing[tire_model.tire_manufacturer.name] = 0
				end
				ht_manus_without_pricing[tire_model.tire_manufacturer.name] += 1
			else
				tire_models_with_pricing += 1
				if ht_manus_with_pricing[tire_model.tire_manufacturer.name].nil?
					ht_manus_with_pricing[tire_model.tire_manufacturer.name] = 0
				end
				ht_manus_with_pricing[tire_model.tire_manufacturer.name] += 1
				@worksheet = nil
				@array_index = 0
				@worksheet_names.each_with_index do |m, i|
					if m == tire_model.tire_manufacturer.name
						@worksheet = @workbook.worksheets[i]
						@array_index = i
						break
					end
				end 
        		## =IF(COUNTIF((G8;J8;L8;R8);">0")>1;SUM(G8;J8;L8;R8)/COUNTIF((G8;J8;L8;R8);">0");"")
        		if @worksheet.nil?
        			@worksheet = @workbook.add_worksheet
		        	#@worksheet.write(0, 0, tire_model.tire_manufacturer.name)
		        	@worksheet.merge_range(0, 0, 0, 5, tire_model.tire_manufacturer.name, manu_format)
		        	@worksheet.write(5, 0, "Size", title_format)
		        	@worksheet.write(5, 1, "Manu. Part #", title_format)
		        	@worksheet.write(5, 2, "Model Name", title_format)
		        	@worksheet.write(5, 3, " ", title_format)
		        	@worksheet.write(5, 4, "MSRP", title_format)
		        	@worksheet.write(5, 5, "TCI Price", title_format)
		        	@worksheet.write(5, 6, "Walmart", title_format)
		        	@worksheet.write(5, 7, "MSRP +- %", title_format)
		        	@worksheet.write(5, 8, "TCI +- %", title_format)
		        	@worksheet.write(5, 9, "Retail +- %", title_format)
		        	@worksheet.write(5, 10, "Pepboys", title_format)
		        	@worksheet.write(5, 11, "MSRP +- %", title_format)
		        	@worksheet.write(5, 12, "TCI +- %", title_format)
		        	@worksheet.write(5, 13, "Retail +- %", title_format)
		        	@worksheet.write(5, 14, "Discount Tire", title_format)
		        	@worksheet.write(5, 15, "MSRP +- %", title_format)
		        	@worksheet.write(5, 16, "TCI +- %", title_format)
		        	@worksheet.write(5, 17, "Retail +- %", title_format)
		        	@worksheet.write(5, 18, "Sears", title_format)
		        	@worksheet.write(5, 19, "MSRP +- %", title_format)
		        	@worksheet.write(5, 20, "TCI +- %", title_format)
		        	@worksheet.write(5, 21, "Retail +- %", title_format)
		        	@array_index = @workbook.worksheets.size - 1
		        	@row_counts << 6
		        	@worksheet_names << tire_model.tire_manufacturer.name
		        	@worksheet.set_column('H:J', 5)
		        	@worksheet.set_column('L:N', 5)
		        	@worksheet.set_column('P:R', 5)
		        	@worksheet.set_column('T:V', 5)
		        	@worksheet.set_column('C:C', 25)
		        	@worksheet.set_column('A:A', 15)
		        	@worksheet.set_column('B:B', 12)
		        	@worksheet.set_column('D:D', 3)
		        	#@worksheet.set_column('F:F', 5, right_border_format)
		        	#@worksheet.set_column('J:J', 5, right_border_format)
		        	#@worksheet.set_column('N:N', 5, right_border_format)
		        	#@worksheet.set_column('R:R', 5, right_border_format)
		        	@worksheet.write(1, 5, '', std_format)
		        	@worksheet.write(2, 5, '', std_format)
		        	@worksheet.write(3, 5, '', std_format)
		        	@worksheet.write(4, 5, '', std_format)
		        	@worksheet.write(0, 9, '', std_format)
		        	@worksheet.write(1, 9, '', std_format)
		        	@worksheet.write(2, 9, '', std_format)
		        	@worksheet.write(3, 9, '', std_format)
		        	@worksheet.write(4, 9, '', std_format)
		        	@worksheet.write(0, 13, '', std_format)
		        	@worksheet.write(1, 13, '', std_format)
		        	@worksheet.write(2, 13, '', std_format)
		        	@worksheet.write(3, 13, '', std_format)
		        	@worksheet.write(4, 13, '', std_format)
		        	@worksheet.write(0, 17, '', std_format)
		        	@worksheet.write(1, 17, '', std_format)
		        	@worksheet.write(2, 17, '', std_format)
		        	@worksheet.write(3, 17, '', std_format)
		        	@worksheet.write(4, 17, '', std_format)
		        end
		        @row_counts[@array_index] +=1
		        @avg_retail = 0
		        @num_retail = 0
		        @num_retail += 1 if tire_model.walmart_price
		        @num_retail += 1 if tire_model.pepboys_price
		        @num_retail += 1 if tire_model.discount_tire_price
		        @num_retail += 1 if tire_model.sears_price
		        @tot_retail = 0
		        @tot_retail += tire_model.walmart_price.to_f if tire_model.walmart_price
		        @tot_retail += tire_model.pepboys_price.to_f if tire_model.pepboys_price
		        @tot_retail += tire_model.discount_tire_price.to_f if tire_model.discount_tire_price
		        @tot_retail += tire_model.sears_price.to_f if tire_model.sears_price
		        if @num_retail > 1
		        	@avg_retail = (@tot_retail / @num_retail).round(2)
		        else
		        	@avg_retail = 0
		        end
		        @worksheet.write(@row_counts[@array_index], 0, tire_model.tire_size.sizestr)
		        @worksheet.write(@row_counts[@array_index], 1, tire_model.manu_part_num)
		        @worksheet.write(@row_counts[@array_index], 2, tire_model.name)
		        @worksheet.write(@row_counts[@array_index], 3, "")
		        @worksheet.write(@row_counts[@array_index], 4, tire_model.msrp_price.to_f) if tire_model.msrp_price
		        if tire_model.tci_price
		        	@worksheet.write(@row_counts[@array_index], 5, tire_model.tci_price.to_f, right_border_format)
		        else
		        	@worksheet.write(@row_counts[@array_index], 5, "", right_border_format)
		        end
		        @worksheet.write(@row_counts[@array_index], 6, tire_model.walmart_price.to_f) if tire_model.walmart_price
		        if tire_model.msrp_price && tire_model.walmart_price
		        	@worksheet.write(@row_counts[@array_index], 7, (((tire_model.walmart_price.to_f - tire_model.msrp_price.to_f) * 100) / tire_model.msrp_price.to_f).round(1))
		        end
		        if tire_model.tci_price && tire_model.walmart_price
		        	@worksheet.write(@row_counts[@array_index], 8, (((tire_model.walmart_price.to_f - tire_model.tci_price.to_f) * 100) / tire_model.tci_price.to_f).round(2))
		        end
		        if @avg_retail > 0 && tire_model.walmart_price
		        	@worksheet.write(@row_counts[@array_index], 9, (((tire_model.walmart_price.to_f - @avg_retail) * 100) / @avg_retail).round(2), right_border_format)
		        else
		        	@worksheet.write(@row_counts[@array_index], 9, "", right_border_format)
		        end
		        @worksheet.write(@row_counts[@array_index], 10, tire_model.pepboys_price.to_f) if tire_model.pepboys_price
		        if tire_model.msrp_price && tire_model.pepboys_price
		        	@worksheet.write(@row_counts[@array_index], 11, (((tire_model.pepboys_price.to_f - tire_model.msrp_price.to_f) * 100) / tire_model.msrp_price.to_f).round(1))
		        end
		        if tire_model.tci_price && tire_model.pepboys_price
		        	@worksheet.write(@row_counts[@array_index], 12, (((tire_model.pepboys_price.to_f - tire_model.tci_price.to_f) * 100) / tire_model.tci_price.to_f).round(2))
		        end
		        if @avg_retail > 0 && tire_model.pepboys_price
		        	@worksheet.write(@row_counts[@array_index], 13, (((tire_model.pepboys_price.to_f - @avg_retail) * 100) / @avg_retail).round(2), right_border_format)
		        else
		        	@worksheet.write(@row_counts[@array_index], 13, "", right_border_format)
		        end
		        @worksheet.write(@row_counts[@array_index], 14, tire_model.discount_tire_price.to_f) if tire_model.discount_tire_price
		        if tire_model.msrp_price && tire_model.discount_tire_price
		        	@worksheet.write(@row_counts[@array_index], 15, (((tire_model.discount_tire_price.to_f - tire_model.msrp_price.to_f) * 100) / tire_model.msrp_price.to_f).round(1))
		        end
		        if tire_model.tci_price && tire_model.discount_tire_price
		        	@worksheet.write(@row_counts[@array_index], 16, (((tire_model.discount_tire_price.to_f - tire_model.tci_price.to_f) * 100) / tire_model.tci_price.to_f).round(2))
		        end
		        if @avg_retail > 0 && tire_model.discount_tire_price
		        	@worksheet.write(@row_counts[@array_index], 17, (((tire_model.discount_tire_price.to_f - @avg_retail) * 100) / @avg_retail).round(2), right_border_format)
		        else
		        	@worksheet.write(@row_counts[@array_index], 17, "", right_border_format)
		        end
		        @worksheet.write(@row_counts[@array_index], 18, tire_model.sears_price.to_f) if tire_model.sears_price
		        if tire_model.msrp_price && tire_model.sears_price
		        	@worksheet.write(@row_counts[@array_index], 19, (((tire_model.sears_price.to_f - tire_model.msrp_price.to_f) * 100) / tire_model.msrp_price.to_f).round(1))
		        end
		        if tire_model.tci_price && tire_model.sears_price
		        	@worksheet.write(@row_counts[@array_index], 20, (((tire_model.sears_price.to_f - tire_model.tci_price.to_f) * 100) / tire_model.tci_price.to_f).round(2))
		        end
		        if @avg_retail > 0 && tire_model.sears_price
		        	@worksheet.write(@row_counts[@array_index], 21, (((tire_model.sears_price.to_f - @avg_retail) * 100) / @avg_retail).round(2), right_border_format)
		        else
		        	@worksheet.write(@row_counts[@array_index], 21, "", right_border_format)
		        end
		    end
		end
        # now write out the found/not found stats
        @worksheet_names.each_with_index do |manu, i|
        	@workbook.worksheets[i].write(2, 0, "No prices found:")
        	@workbook.worksheets[i].write(2, 1, ht_manus_without_pricing[manu].to_i)
        	@workbook.worksheets[i].write(3, 0, "Prices found:")
        	@workbook.worksheets[i].write(3, 1, ht_manus_with_pricing[manu].to_i)

        	# now write formulas for average differentiation
        	## =IF(ISBLANK(H9);"";IF(SUM(G9:G94)>0;SUM(G9:G94)/COUNTIF(G9:G94;">0");"no values entered"))

        end

        @workbook.close        
    end
end