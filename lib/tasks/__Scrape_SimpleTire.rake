require 'nokogiri'
require 'rest_client'

namespace :ScrapeSimpleTire do
    desc "Get tire information from SimpleTire.com"
    task populate: :environment do
        #brands = ["Achilles", "Atturo", "Capitol", "Mayrun", "Runway"]
        #brands = ["Westlake", "Goodride", "Negotiator", "Trazano", "Geostar", "Accelera"]
        #brands = ["Durun", "Deestone", "Sumic", "Aurora", "Kenda", "Milestar", "Primewell", "Linglong", "Crosswind", "Winrun"]
        #brands = ["National"]
        #brands = ["Kumho"]
        brands = ["National"]
        brands.each do |brand|
            manu = TireManufacturer.find_by_name(brand)
            if manu.nil?
                puts "Creating new manufacturer record for " + brand
                manu = TireManufacturer.new(:name => brand)
                manu.save
            end

            # Now scrape SimpleTires's "Inventory" page to get list of tire models
            # for this manufacturer
            inventory_url = "http://www.simpletire.com/#{brand.downcase}-tires"

            # special case for multi mile
            #inventory_url = "http://www.simpletire.com/multi-mile-tires"
            #inventory_url = inventory_url.gsub(/[' ']/, '%20')

            puts "Inventory URL: #{inventory_url}"

            inventory_response = RestClient.get inventory_url
            html_tire_models = Nokogiri::HTML(inventory_response.to_s)

            html_tire_models.xpath("//div[@class='tileHead']").each do |model_tmp|
                begin
                    #puts "links to #{model_href.attribute('href').text}"
                    model = model_tmp.text()
                    model_href = model_tmp.xpath(".//a")

                    ##next if model != 'Solus KH18'
                    
                    puts "-----> " + brand + " " +  model

                    model_url = "http://simpletire.com#{model_href.attribute('href').text}"
                    puts "opening #{model}"
                    model_response = RestClient.get model_url
                    html_model = Nokogiri::HTML(model_response.to_s)

                    html_model.xpath("//a[contains(., 'View Details')]").each do |ajax_href|
                        ajax_id = ajax_href.attribute("id").text().strip
                        ajax_id = ajax_id.gsub(/expand\-/, '')
                        ajax_url = "http://simpletire.com/catalog_browse/item_detail/#{ajax_id}"
                        ajax_response = RestClient.get(ajax_url)
                        html_ajax = Nokogiri::HTML(ajax_response.to_s)

                        size = html_ajax.xpath("//span[contains(@class, 'tire-size')]").text().strip()
                        part_number = html_ajax.xpath("//span[contains(@class, 'part-number')]").text().strip()
                        service_description = html_ajax.xpath("//span[contains(@class, 'speed-rating')]").text().strip()
                        warranty = html_ajax.xpath("//span[contains(@class, 'warranty')]").text().strip()
                        sidewall = html_ajax.xpath("//span[contains(@class, 'side-wall')]").text().strip()
                        loadrange = html_ajax.xpath("//span[contains(@class, 'load-range')]").text().strip()
                        utqg = html_ajax.xpath("//span[contains(@class, 'utqg')]").text().strip()
                        price = html_ajax.xpath("//span[contains(@class, 'amount')]").text().strip()

                        # parse the service code
                        arSvc = /(\d{2,3})(\D)/.match(service_description)
                        if arSvc
                            load_index = arSvc[1]
                            speed_rating = arSvc[2]
                        else
                            puts "**** COULD NOT PARSE SVC #{service_description}"
                            load_index = ""
                            speed_rating = ""
                        end

                        # let's parse the size
                        arSize = /(|P|LT)(\d{3})(x|\/)(\d{2})(R|ZR)(\d{2})/.match(size)
                        if !arSize
                            puts "**** COULD NOT PARSE #{size}"
                        else
                            # now get the parts
                            tire_code = arSize[1]
                            tire_code = "P" if tire_code == ""
                            sizestr = "#{arSize[2]}/#{arSize[4]}R#{arSize[6]}"
                            ts = TireSize.find_by_sizestr(sizestr)
                            if !ts 
                                puts "**** COULD NOT FIND SIZE #{sizestr}"
                            else
                                if true
                                    puts "**********"
                                    puts "MODEL: #{model}"
                                    puts "SIZE: #{tire_code} - #{sizestr}"
                                    puts "PART: #{part_number}"
                                    puts "SVC: #{load_index} #{speed_rating}"
                                    puts "WTY: #{warranty}"
                                    puts "SIDE: #{sidewall}"
                                    puts "LOAD: #{loadrange}"
                                    puts "UTQG: #{utqg}"
                                    puts "PRICE: #{price}"
                                    puts "***********"
                                    puts ""
                                end

                                tm = TireModel.find_by_tire_manufacturer_id_and_tire_size_id_and_name(manu.id, ts.id, model)
                                if tm 
                                    puts "Updating #{manu.name} #{model} #{ts.sizestr}"
                                else
                                    puts "Creating #{manu.name} #{model} #{ts.sizestr}"
                                    tm = TireModel.new
                                    tm.tire_manufacturer_id = manu.id
                                    tm.tire_size_id = ts.id 
                                    tm.name = model 
                                end

                                tm.tire_code = tire_code
                                tm.product_code = part_number
                                tm.sidewall = sidewall
                                tm.utqg_treadwear = utqg 
                                ##tm.load_index = load_index
                                tm.speed_rating = speed_rating
                                ##tm.orig_cost = price 
                                ##tm.construction = xxx
                                ##tm.weight = xxx
                                tm.warranty_miles = warranty

                                if true
                                    tm.save
                                end
                            end
                        end
                    end
                rescue Exception => e
                    puts "**** ERROR PARSING PAGE " + e.message
                end
            end
        end
    end
end
