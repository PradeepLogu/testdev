require 'nokogiri'
require 'open-uri'

def ReadDataArlington(url)
	url = URI::encode(url)
	result = ""
    (1..5).each do |i|
        begin
    		result = RestClient.get url
   			break
   		rescue Exception => e 
   			#puts "Error processing #{url} - try again"
   			result = ""
   		end
   	end
   	return result
end

def PostData(post_url, function, page_no)
	result = ""

	if post_url.blank?
		post_url = "http://www.arlingtonautotire.com/searchresults.htm?fn=#{function}&autoPage=1&autoPageNum=#{page_no}"
	end
    (1..5).each do |i|
        begin
            result = RestClient.post post_url,  :user_agent => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) "
            break
        rescue Exception => e 
            puts "Error processing #{post_url}: #{e.to_s} - try again"
            result = ""
        end
    end
    return result
end

def translate_mfr_name_arlington(name)
    case name.strip()
    when 'Cooper Tire'
        'Cooper'
    when 'Continental Tire'
        'Continental'
   	when 'BFGoodrich'
   		'BF Goodrich'
    when 'General Tire'
    	'General'
	when 'Hankook Tires'
		'Hankook'
	when 'Kelly Tires'
		'Kelly'
    else
        name.strip()
    end
end

def translate_model_name_arlington(name)
    case name.strip()
    when "Commercial T/A All-Season"
    	"Commercial T/A All Season"
    when "g-Force R1 & R1S"
    	"g-Force R1"
	when "g-ForceT/A Drag Radial"
		"g-Force T/A Drag Radial"
	when "Dueler A/T REVO 2 with Uni-T"
		"Dueler A/T Revo 2"
	when "Dueler H/L 422 Ecopia (eco)"
		"Dueler H/L 422 Ecopia"
	when "Turanza with Serenity Technology"
		"Turanza w/Serenity Technology"
	when "Dueler HP Sport"
		"Dueler H/P Sport"
	when "Conti ProContact"
		"ContiProContact"
	when "Conti ExtremeContact"
		"ContiExtremeContact"
	when "Conti PremierContact"
		"ContiPremiumContact"
	when "Conti SportContact 2"
		"ContiSportContact 2"
	when "Conti SportContact 3"
		"ContiSportContact 3"
	when "Extreme WinterContact"
		"ExtremeWinterContact"
	when "Conti SportContact"
		"ContiSportContact"
	when "Vanco 4 Season"
		"Vanco4Season"
	when "Discoverer S/T Maxx"
		"Discoverer S/T MAXX"
	when "Discoverer M+S Sport Utility Vehicle"
		"Discoverer M+S Sport"
	when "Lifeliner GLS (T)"
		"Lifeliner GLS"
	when "SP Sport 01 A DSST ROF"
		"SP Sport 01 DSST ROF"
	when "Rover H/T (P)"
		"Rover H/T"
	when "SP Sport 4000 DSST"
		"SP Sport 4000 DSST CTT"
	when "SP 31A"
		"SP31 A"
	when "SP Winter M3 DSST ROF"
		"SP Winter Sport M3 DSST ROF"
	when "SP 50"
		"SP50"
	when "Signature  CS"
		"Signature CS"
	when "Destination LE with UNI-T"
		"Destination LE"
	when "Fortera HL"
		"Fortera HL (P)"
	when "Assurance CS Fuel Max"
		"Assurance cs Fuel Max"
	when "Assurance CS TripleTred All-Season"
		"Assurance TripleTred"
	when "Assurance TripleTred All Season"
		"Assurance TripleTred"
	when "Ultra Grip Winter"
		"Ultra Grip"
	when "Ultra Grip Ice WRT Commuter Touring"
		"Ultra Grip Ice WRT"
	when "Wrangler MT/R with Kevlar"
		"Wrangler MT/R"
	when "Eagle Ultra Grip GW-3"
		"Eagle Ultra Grip GW3"
	when "Eagle Ultra Grip GW-2"
		"Eagle Ultra Grip GW2"
	when "Eagle F1 Super Car EMT"
		"Eagle F1 Supercar EMT"
	when "DynaPro ATM RF10"
		"Dynapro ATM RF10"
	when "Winter Ipike W409"
		"Winter i*pike W409"
	when "Ventus S1 Noble 2 H452"
		"Ventus S1 noble2"
	when "Mileage Plus II /Optimo H725"
		"Mileage Plus II H725"
	when "Ventus V2 Concept 2"
		"Ventus V2 concept2"
	when "Zovac HPW401"
		"Zovac HP W401"
	when "DynaPro AT RF08"
		"Dynapro AT RF08"
	when "DynaPro AS RH03-LT"
		"Dynapro AS RH03"
	when "Eco Solus KL21"
		"eco Solus KL21"
	when "Ecsta XS KU36"
		"Ecsta XS"
	when "XPS Traction"
		"XPS TRACTION"
	when "XPS Rib"
		"XPS RIB"
	when "N 5000"
		"N5000"
	when "N 7000"
		"N7000"
	when "Cinturato P7 All Season"
		"Cinturato P7"

    else
        name.strip()
    end
end

namespace :ScrapeArlingtonAutoTire do
    manu_list = "StarFire|Uniroyal|Dakota|Nitto|Arizonian|BF Goodrich|BFGoodrich|Bridgestone|Continental|Dunlop|Falken|Firestone|Goodyear|Hankook|Kumho|Michelin|Multi-Mile|Nexen|Pirelli|Sumitomo|Toyo|Yokohama|Savero|Winston|Continetnal"
    desc "Scrape ArlingtonAutoTire.com for data"
    task populate: :environment do
        start_time = Time.now

        records_added_hash = {}
        records_deleted_hash = {}

        tire_store = TireStore.find_by_name_and_city('Arlington Auto & Tire', 'Poughkeepsie')
        if !tire_store
            puts "**** CREATING TIRESTORE RECORD"
            tire_store = TireStore.new
            tire_store.name = 'Arlington Auto & Tire'
            tire_store.address1 = '1 Peckham Rd'
            tire_store.city = 'Poughkeepsie'
            tire_store.state = 'NY'
            tire_store.zipcode = '12603'
            tire_store.phone = '8454712800'
            tire_store.contact_email = 'arlingtonautotire@gmail.com'
            tire_store.save
            tire_store.errors.each do |e|
                puts e.to_s 
            end
        end

        ###aat_base_url = "http://www.arlingtonautotire.com/searchresults.htm?&sortOrder=pricelh&layout=list&autoPage=1"#&autoPageNum=3
        
        aat_response = ''
        tot_processed = 0
        valid_count = 0
        confidence = FuzzyStringMatch::JaroWinkler.create(:pure)

        encoding_options = {
            :invalid           => :replace,  # Replace invalid byte sequences
            :undef             => :replace,  # Replace anything not defined in ASCII
            :replace           => '',        # Use a blank for those replacements
            :universal_newline => true       # Always break lines with \n
        }
        
        models_found = 0
        models_not_found = 0
        models_guessed = 0
        records_added = 0

        main_response = ReadDataArlington("http://www.arlingtonautotire.com/searchresults.htm")

        if !main_response.to_s.blank?
        	# find all the brand links
        	main_data = Nokogiri::HTML(main_response.to_s)

        	main_data.xpath("//div[@id='dialogBrand']/table//td/ul/li/a").each do |brand_info| # /tr/td/ul/li/a").each do |brand_info|
        		brand_url_temp = brand_info.attribute("href")
        		brand_url = "http://www.arlingtonautotire.com/#{brand_url_temp}"

        		uri = URI.parse(brand_url)
        		path = uri.path.gsub(/\//, '')

				page_no = 1
		    	aat_response = PostData("", path, page_no)

		        while !aat_response.to_s.include?("auto_pagnation_end") && !aat_response.blank? do
					html_data = Nokogiri::HTML(aat_response.to_s)

					html_data.xpath("//a[contains(@class, 'ecomm_button') and contains(@class, 'viewDetails')]").each do |tire_model_info|
						details_url_temp = tire_model_info.attribute("href")

						details_url = "http://www.arlingtonautotire.com/#{details_url_temp}"

						details_response = ReadDataArlington(details_url)
						if details_response != ""
							details_data = Nokogiri::HTML(details_response.to_s)

							manu_name_raw = details_data.xpath("//span[@itemprop='brand']").text().encode(Encoding.find('ASCII'), encoding_options)
							manu_name = translate_mfr_name_arlington(manu_name_raw)

							manu = TireManufacturer.find_by_name(manu_name)

							if !manu.nil?
								model_name = details_data.xpath("//span[@itemprop='name']").text().encode(Encoding.find('ASCII'), encoding_options).strip()

								if model_name.end_with?(' Tire')
									model_name = model_name.gsub(/\ Tire$/, '')
								end

								model_name = translate_model_name_arlington(model_name)

								tmi = TireModelInfo.find_by_tire_manufacturer_id_and_tire_model_name(manu.id, model_name)

								if tmi.nil?
									matcher = FuzzyMatch.new(TireModelInfo.find(:all,  :conditions => ['tire_manufacturer_id = ?', manu.id]), :read => :tire_model_name)
                                    best_guess = matcher.find(model_name)
                                    if best_guess
                                        # check our confidence score
                                        con = confidence.getDistance(best_guess.tire_model_name.downcase, model_name.downcase)
                                        if con < 0.9
											models_not_found += 1
										else
											models_not_found += 1
											###models_guessed += 1
                                        end
                                    else
										models_not_found += 1
                                    end
								else
									puts "Found #{manu_name} #{model_name}"
									models_found += 1

									ar_product_id = /.*productId=(\d{1,99})\&.*/.match(details_url)
									if ar_product_id && ar_product_id.length > 1
										product_id = ar_product_id[1]
										product_url = "http://www.arlingtonautotire.com/Services/ProductDetailServices.aspx?action=getprintpage&productId=#{product_id}"
										product_response = ReadDataArlington(product_url)
										if product_response != ""
											product_data = Nokogiri::HTML(product_response.to_s)

											#puts product_data.to_s
											product_data.xpath("//table[@class='pd-partnum-table']//tr").each do |size_data|
												if !size_data.to_s.include?("Part #")
													ar_size = /TIRE SIZE: (|LT|P)(\d{3})\/(\d{2,3})(R|ZR|RF|ZRF)(\d{2,3})/.match(size_data.to_s)
													if ar_size && ar_size.length > 3
														tire_code = ar_size[1]
														sizestr = "#{ar_size[2]}/#{ar_size[3]}R#{ar_size[5]}"

														ts = TireSize.find_by_sizestr(sizestr)
														if ts.nil?
															puts "TireSize #{sizestr} not found..."
															ts = TireSize.find_or_create_by_sizestr(sizestr)
														end

														# get the model's attributes
														speed_rating = load_index = load_range = utqg = warranty = sidewall = tread_depth = rim_size = max_load = svc_description = ""
														ar_all_attributes = size_data.to_s.split("<br>")
														ar_all_attributes.each do |s|
															if s.include?("SPEED RATING:")
																speed_rating = s.gsub(/SPEED\ RATING\:/, '').strip()
															elsif s.include?("LOAD INDEX:")
																load_index = s.gsub(/LOAD\ INDEX\:/, '').strip()
															elsif s.include?("LOAD RANGE:")
																load_range = s.gsub(/LOAD\ RANGE\:/, '').strip()
															elsif s.include?("UTQG:")
																utqg = s.gsub(/UTQG\:/, '').strip()
															elsif s.include?("TIRE WARRANTY (U.S.):")
																warranty = s.gsub(/TIRE\ WARRANTY\ \(U\.S\.\)\:/, '').gsub(/mi\./, '').strip()
															elsif s.include?("SIDEWALL:")
																sidewall = s.gsub(/SIDEWALL\:/, '').strip()
															elsif s.include?("TREAD DEPTH:")
																tread_depth = s.gsub(/TREAD\ DEPTH\:/, '').gsub(/\/32\ in\./, '').strip()
															elsif s.include?("SERVICE DESCRIPTION:")
																svc_description = s.gsub(/SERVICE\ DESCRIPTION\:/, '').strip()
															end
														end

														utqg_treadwear = utqg_temp = utqg_traction = ""
														ar_utqg = /(\d{2,3}) (\w{1,2}) (\w)/.match(utqg)
														if ar_utqg and ar_utqg.size >= 3
															utqg_treadwear = ar_utqg[1]
															utqg_traction = ar_utqg[2]
															utqg_temp = ar_utqg[3]
														end

														# get the price
														manu_part_num = size_data.xpath("td")[0].text()
														#puts "MANU: #{manu_part_num}"
														post_url = "http://www.arlingtonautotire.com/Services/ProductDetailServices.aspx?action=gettireandwheelprices&tire_pns=#{manu_part_num}~#{manu_name_raw}&wheel_pns=&brand=#{manu_name_raw}&locationId=7412"
														priceJSON = PostData(post_url, "", "")
														if priceJSON.blank?
															price = ""
														else
															begin
																price = JSON.parse(priceJSON).first["price"]
															rescue Exception => e
																puts "Could not parse price #{priceJSON}"
																price = ""
															end
														end

														if price.blank?
															puts "Could not get a price. #{priceJSON}"
														else
															puts "speed: #{speed_rating}"
															puts "load index: #{load_index}"
															puts "load range: #{load_range}"
															puts "utqg: #{utqg_treadwear}/#{utqg_traction}/#{utqg_temp}"
															puts "warranty: #{warranty}"
															puts "sidewall: #{sidewall}"
															puts "tread: #{tread_depth}"
															puts "price: #{price}"

															tire_model = TireModel.find_by_tire_manufacturer_id_and_tire_size_id_and_tire_model_info_id_and_tire_code(manu.id, ts.id, tmi.id, tire_code)
															if tire_model.nil?
																tire_model = TireModel.find_by_tire_manufacturer_id_and_tire_size_id_and_tire_model_info_id(manu.id, ts.id, tmi.id)
															end

															### size is good, let's go ahead and create this model.
															if tire_model.nil?
																tire_model = TireModel.find_or_create_by_tire_manufacturer_id_and_tire_size_id_and_tire_model_info_id_and_tire_code(manu.id, ts.id, tmi.id, tire_code)
																tire_model.name = tmi.tire_model_name
																tire_model.save
															end

															# update the model info
												            tire_model.utqg_temp = utqg_temp
												            tire_model.utqg_traction = utqg_traction
												            tire_model.utqg_treadwear = utqg_treadwear
												            tire_model.load_index = load_index
												            tire_model.speed_rating = speed_rating
												            tire_model.tread_depth = tread_depth
												            tire_model.sidewall = sidewall
											            	tire_model.save

															# now the listing
	                                        				tl = TireListing.find_by_source_and_tire_size_id(details_url, ts.id)
	                                        				if !tl
	                                        					records_added += 1
	                                            				tl = TireListing.new
	                                        				end

				                                            tl.tire_store_id = tire_store.id
				                                            tl.source = details_url
				                                            tl.tire_manufacturer_id = manu.id
				                                            tl.quantity = 4
				                                            tl.includes_mounting = false
				                                            tl.remaining_tread = tread_depth
				                                            tl.tire_size_id = ts.id
				                                            tl.price = price
				                                            tl.tire_model_id = tire_model.id
				                                            tl.is_new = true
				                                            tl.stock_number = product_id if product_id
				                                            tl.sell_as_set_only = false
				                                            tl.save

				                                            valid_count += 1
												       	end
													else
														# couldn't find the size...might report more info here
														tire_code = ""
														sizestr = ""

														ar_sizestr = /TIRE SIZE: (.+)\<(.*)SPEED.*/.match(size_data.to_s)
														if ar_sizestr && ar_sizestr.length > 1
															#puts "Size not found #{ar_sizestr[1]}"
														else
															ar_sizestr = /TIRE SIZE: (.*)<br>LOAD/.match(size_data.to_s)
															if ar_sizestr && ar_sizestr.length > 1
																#puts "Size not found #{ar_sizestr[1]}"
															else
																#puts "Size not found #{size_data}"
															end
														end
													end
												end
											end
										end
									else
										puts "could not parse URL: #{details_url}"
									end

                                    #tl = TireListing.find_by_redirect_to(tk_listing_url)
                                    #    if !tl
                                    #        tl = TireListing.new
                                    #    end
								end

								puts "--------------------"
							else
								puts "*NOT PROCESSING #{manu_name}*"
							end
						end
					end

			        page_no += 1
		        	aat_response = PostData("", path, page_no)
		        end
		    end
	    end

        # which ones did we not touch?
        records_deleted = 0
        untouched = TireListing.where("tire_store_id = ? and updated_at < ?", tire_store.id, start_time)
        untouched.each do |r|
            puts "Deleting out of date: #{r.id} #{r.description}"
            r.delete
            records_deleted += 1
        end
        #puts "Touched #{touched}"

        puts "Successfully processed #{valid_count} records."

        body_text = "Successfully processed #{valid_count} of #{html_data.xpath("//a[@class='productnamecolor colors_productname']/@href").count}\n\n"
        body_text += "#{tire_store.name}\n"
        body_text += "---------------------------\n"
        body_text += "Added #{records_added}\n"
        body_text += "Deleted #{records_deleted}\n\n"

        ActionMailer::Base.mail(:from => "mail@treadhunter.com", 
        	:to => system_process_completion_email_address(), 
        	:subject => "Processed Tire Kingz", 
        	:body => "#{body_text}").deliver                          


        puts "Models Found: #{models_found}"
        puts "Models not found: #{models_not_found}"
        puts "Models guessed: #{models_guessed}"

        #puts all_manus.join("\n")





















        if false
        valid_count = 0
        nbsp = Nokogiri::HTML("&nbsp;").text
        confidence = FuzzyStringMatch::JaroWinkler.create(:pure)

        if tk_response != '' # there was no error
            html_data = Nokogiri::HTML(tk_response.to_s)

            html_data.xpath("//a[@class='productnamecolor colors_productname']").each do |tk_listing_xpath|
                tot_processed += 1
                if tot_processed > 9999
                    break
                end

                #puts "#{tk_listing_xpath}"
                tk_listing_url = tk_listing_xpath.attribute('href').text().strip()

                if tk_listing_url.to_s != "http://www.tirekingzatl.com/265-35-18-Pirelli-Pzero-Nero-p/dec-748.htm" &&
                    tk_listing_url.to_s != "http://www.tirekingzatl.com/245-60-18-Nitto-NT850-Premium-Used-Tires-p/dec-560.htm" &&
                    tk_listing_url.to_s != "http://www.tirekingzatl.com/285-75-16-StarFire-SF-510-LT-Used-Tires-p/dec-678.htm" &&
                    tk_listing_url.to_s != "http://www.tirekingzatl.com/225-75-15-Goodyear-Marathon-Radial-Used-Tires-p/dec-737.htm" &&
                    tk_listing_url.to_s != "http://www.tirekingzatl.com/255-65-16-Michelin-Cross-Terrain-SUV-Used-Tires-p/dec-505.htm" &&
                    tk_listing_url.to_s != "http://www.tirekingzatl.com/265-75-16-Winner-A-T-Used-Tires-p/dec-711.htm" &&
                    tk_listing_url.to_s != "http://www.tirekingzatl.com/225-65-17-Yokohama-YK520-Used-Tires-p/dec-538.htm" &&
                    tk_listing_url.to_s != "http://www.tirekingzatl.com/245-55-17-Michelin-Primacy-MXM4-Zp-Used-Tires-p/dec-406.htm"
                    listing_response = ''
                    (1..5).each do |i|
                        begin
                            listing_response = ReadData(tk_listing_url.to_s)
                            break
                        rescue Exception => e
                            puts "Error processing #{tk_listing_url} - #{e.to_s}"
                        end
                    end

                    if listing_response != ''
                        listing_data = Nokogiri::HTML(listing_response.to_s)
                        touched = 0

                        listing_description = listing_data.xpath("//span[@itemprop='description']").text()
                        info = /(\d{3})\/(\d{2})\/(\d{2}).*(#{manu_list}).(.*)[Uu]sed [Tt]ire.*/.match(listing_description)
                        info = /(\d{3})\/(\d{2})\/(\d{2}).*(#{manu_list}).(.*)\. This set.*/.match(listing_description) if info.nil?
                        info = /(\d{3})\/(\d{2})\/(\d{2}).*(#{manu_list}).(.*)\. This pair.*/.match(listing_description) if info.nil?

                        if !info
                            puts "Skipping #{tk_listing_url} - could not process."
                        else
                            sizestr = "#{info[1]}/#{info[2]}R#{info[3]}"
                            manu_name = translate_mfr_name(info[4].strip().gsub(nbsp, ''))
                            model_name = info[5].strip().gsub(nbsp, '')

                            tread = /(\d*\.\d)\/32nd/.match(listing_description)
                            tread = /(\d*)\/32nd/.match(listing_description) if !tread
                            if tread
                                remaining_tread = tread[1]
                            else
                                remaining_tread = ''
                            end

                            price_text = listing_data.xpath("//font[@class='pricecolor colors_productprice']").text()
                            price = /Our Price:.*\$(.*)/.match(price_text)
                            price = /Sale Price:.*\$(.*)/.match(price_text) if !price
                            if price
                                price_str = price[1]

                                manu = TireManufacturer.find_by_name(manu_name)
                                size = TireSize.find_by_sizestr(sizestr)
                                listing_title = listing_data.xpath("//span[@itemprop='name']").text().strip()
                                qty = /^\((\d)\)/.match(listing_title)
                                product_code_text = listing_data.xpath("//span[@class='product_code']").text().strip()

                                if !qty
                                    puts "*** NO QTY IN #{listing_title}"
                                end

                                if manu && size && qty
                                    model = TireModel.find(:first, :conditions => ["tire_manufacturer_id = ? and tire_size_id = ? and lower(name) = ?", manu.id, size.id, model_name.downcase])
                                    if model.nil?
                                        model = TireModel.find(:first, :conditions => ["tire_manufacturer_id = ? and tire_size_id = ? and lower(name) = ?", manu.id, size.id, translate_model_name(model_name).downcase])
                                    end

                                    if model.nil?
                                        # find best match
                                        matcher = FuzzyMatch.new(TireModel.find(:all,  :conditions => ['tire_manufacturer_id = ? and tire_size_id = ?', manu.id, size.id]), :read => :name)
                                        model = matcher.find(model_name)
                                        if model
                                            # check our confidence score
                                            con = confidence.getDistance(model.name.downcase, model_name.downcase)
                                            if con < 0.9
                                                model = nil
                                            else
                                                puts "Fuzzy match (#{con}) - #{model.name}/#{model_name}"
                                            end
                                        end
                                    end

                                    if model 
                                        valid_count += 1
                                        # Check and see if we've already listed this tire.
                                        # if not, create a new one
                                        tl = TireListing.find_by_redirect_to(tk_listing_url)
                                        if !tl
                                            tl = TireListing.new
                                        end

                                        photo1_url = listing_data.xpath("//a[@id='product_photo_zoom_url']").attribute("href").text().strip()
                                        #puts "#{photo1_url}"
                                        tl.photo1 = open("http:#{photo1_url}")

                                        begin
                                            photo2_url = listing_data.xpath("//span[@id='altviews']/a[2]/@href").text().strip()
                                            tl.photo2 = open("http:#{photo2_url}")
                                        rescue Exception => e
                                            puts "#{e.to_s} processing Photo2"
                                        end

                                        begin
                                            photo3_url = listing_data.xpath("//span[@id='altviews']/a[3]/@href").text().strip()
                                            tl.photo3 = open("http:#{photo3_url}")
                                        rescue Exception => e
                                            puts "#{e.to_s} processing Photo3"
                                        end

                                        begin
                                            photo4_url = listing_data.xpath("//span[@id='altviews']/a[4]/@href").text().strip()
                                            tl.photo4 = open("http:#{photo4_url}")
                                        rescue Exception => e
                                            puts "#{e.to_s} processing Photo4"
                                        end

                                        if product_code_text
                                            tire_store = tire_stores_hash[product_code_text[0..2]]
                                            records_added_hash[product_code_text[0..2]] += 1
                                        else
                                            tire_store = tire_stores_hash.first
                                            records_added_hash[0] += 1
                                        end

                                        if tire_store.nil?
                                            puts "Could not find store for #{product_code_text[0..2]} - #{tk_listing_url}"
                                        else
                                            tl.tire_store_id = tire_store.id
                                            tl.source = 'TireKingzAtl.com'
                                            tl.tire_manufacturer_id = manu.id
                                            tl.quantity = qty[1]
                                            tl.includes_mounting = false
                                            tl.remaining_tread = remaining_tread
                                            tl.tire_size_id = size.id
                                            tl.price = price_str
                                            tl.tire_model_id = model.id
                                            tl.is_new = false
                                            tl.stock_number = product_code_text if product_code_text
                                            tl.sell_as_set_only = true
                                            tl.redirect_to = tk_listing_url
                                            tl.save
                                        end

                                        #if !tl.new_record?
                                        #    tl.touch
                                        #    touched += 1
                                        #end
                                    else
                                        puts "#{tk_listing_url}"
                                        #puts "----> #{price_str}"
                                        #puts "---> Remaining tread: #{remaining_tread}" if tread
                                        puts "*** UNABLE TO FIND MODEL #{manu.name} #{sizestr} #{model_name} (#{translate_model_name(model_name)})"
                                    end
                                else
                                    if !manu 
                                        puts "*** Unable to find manufacturer #{manu_name}"
                                    end
                                    if !size 
                                        puts "*** Unable to find size #{sizestr}"
                                    end
                                end
                            else
                                puts "*** unable to process price #{price_text}"
                            end
                        end
                    end
                end
            end

            # which ones did we not touch?
            tire_stores_hash.each do |k, tire_store|
                untouched = TireListing.where("tire_store_id = ? and updated_at < ?", tire_store.id, start_time)
                untouched.each do |r|
                    puts "Deleting out of date: #{r.id} #{r.description}"
                    r.delete
                    records_deleted_hash[k] += 1                    
                end
            end
            #puts "Touched #{touched}"

            puts "Successfully processed #{valid_count} records."

            body_text = "Successfully processed #{valid_count} of #{html_data.xpath("//a[@class='productnamecolor colors_productname']/@href").count}\n\n"
            tire_stores_hash.each do |k, tire_store|
                body_text += "#{tire_store.name}\n"
                body_text += "---------------------------\n"
                body_text += "Added #{records_added_hash[k]}\n"
                body_text += "Deleted #{records_deleted_hash[k]}\n\n"
            end

            ActionMailer::Base.mail(:from => "mail@treadhunter.com", 
            	:to => system_process_completion_email_address(), 
            	:subject => "Processed Tire Kingz", 
            	:body => "#{body_text}").deliver                          
        else
            puts "Unable to read URL: #{tk_url}.  Please check this URL to see if make and model were entered correctly."
        end
    	end
    end
end