require 'nokogiri'
require 'open-uri'

namespace :ScrapeMaxxisSite do
    desc "Create tire manufacturers data from Maxxis.com"
    task populate: :environment do
        tire_make = "Maxxis"
        create_records = true

        #TireSize.find_or_create_by_sizestr("165/60R14")
        TireSize.find_or_create_by_sizestr("185/50R14")
        TireSize.find_or_create_by_sizestr("225/40R16")
        TireSize.find_or_create_by_sizestr("165/50R15")
        TireSize.find_or_create_by_sizestr("175/70R12")
        TireSize.find_or_create_by_sizestr("135/70R15")
        TireSize.find_or_create_by_sizestr("165/55R15")
        TireSize.find_or_create_by_sizestr("195/80R15")
        TireSize.find_or_create_by_sizestr("205/80R14")
        TireSize.find_or_create_by_sizestr("155/70R12")
        TireSize.find_or_create_by_sizestr("185/75R16")

        manu = TireManufacturer.find_or_create_by_name(tire_make)

        invalid_tmi = []
        invalid_size = []
        all_products = []

        model_urls = [
                        "http://www.maxxis.com/AutomobileLight-Truck/High-Performance/MA-Z1-Victra.aspx",
                        "http://www.maxxis.com/AutomobileLight-Truck/High-Performance/MA-Z4S-Victra.aspx",
                        "http://www.maxxis.com/AutomobileLight-Truck/High-Performance/MA-V1.aspx",
                        "http://www.maxxis.com/AutomobileLight-Truck/High-Performance/M35-Victra-Asymmet.aspx",
                        "http://www.maxxis.com/AutomobileLight-Truck/High-Performance/MA-i-Pro-Victra-i-Pro.aspx",
                        "http://www.maxxis.com/AutomobileLight-Truck/High-Performance/MS300-Waltz.aspx",
                        "http://www.maxxis.com/AutomobileLight-Truck/High-Performance/ZR9-Victra1.aspx",
                        "http://www.maxxis.com/AutomobileLight-Truck/High-Performance/PRO-R1-Victra.aspx",
                        "http://www.maxxis.com/AutomobileLight-Truck/Passenger/MA-T1-Escapade.aspx",
                        "http://www.maxxis.com/AutomobileLight-Truck/Passenger/MA-P1.aspx",
                        "http://www.maxxis.com/AutomobileLight-Truck/Passenger/MA-1.aspx",
                        "http://www.maxxis.com/AutomobileLight-Truck/Passenger/MA-202.aspx",
                        "http://www.maxxis.com/AutomobileLight-Truck/Light-Truck-SUV/CV-01-Escapade-CUV.aspx",
                        "http://www.maxxis.com/AutomobileLight-Truck/Light-Truck-SUV/HT-750-Bravo-Series.aspx",
                        "http://www.maxxis.com/AutomobileLight-Truck/Light-Truck-SUV/HT-760-Bravo-Series.aspx",
                        "http://www.maxxis.com/AutomobileLight-Truck/Light-Truck-SUV/HT-770-Bravo-Series.aspx",
                        "http://www.maxxis.com/AutomobileLight-Truck/Light-Truck-SUV/MA-751-Bravo-Series.aspx",
                        "http://www.maxxis.com/AutomobileLight-Truck/Light-Truck-SUV/MA-752-Bravo-Series.aspx",
                        "http://www.maxxis.com/AutomobileLight-Truck/Light-Truck-SUV/AT-771-Bravo-Series.aspx",
                        "http://www.maxxis.com/AutomobileLight-Truck/Light-Truck-SUV/MA-S1-Marauder.aspx",
                        "http://www.maxxis.com/AutomobileLight-Truck/Light-Truck-SUV/MA-S2-Marauder-II.aspx",
                        "http://www.maxxis.com/AutomobileLight-Truck/Light-Truck-SUV/MA-Z4S-Victra-SUV.aspx",
                        "http://www.maxxis.com/AutomobileLight-Truck/Light-Truck-SUV/MT-753-Bravo-Series.aspx",
                        "http://www.maxxis.com/AutomobileLight-Truck/Light-Truck-SUV/MT-754-Buckshot-Mudder.aspx",
                        "http://www.maxxis.com/AutomobileLight-Truck/Light-Truck-SUV/MT-762-Bighorn.aspx",
                        "http://www.maxxis.com/AutomobileLight-Truck/Light-Truck-SUV/UE-168N-Bravo-Series.aspx",
                        "http://www.maxxis.com/AutomobileLight-Truck/Light-Truck-SUV/HP-600-Bravo-Series.aspx",
                        "http://www.maxxis.com/AutomobileLight-Truck/Light-Truck-SUV/AT-771-Bravo-Series.aspx"
                    ]

        model_urls.each do |model_url|
            puts model_url
            model_response = ''
            (1..5).each do |i|
                begin
                    model_response = ReadData(model_url)
                    break
                rescue Exception => e 
                    puts "Error processing #{model_url}: #{e.to_s} - try again"
                end
            end
            if model_response != ''
                model_data = Nokogiri::HTML(model_response.to_s)

                model_name = model_data.xpath("//div[@id='tireDetailArea']/h2").text.strip()
                img = URI.join(model_url, model_data.xpath("//div[@class='tireDetailImage']/img/@src").first.text.strip()).to_s
                    
                puts ""
                puts ""
                puts "MODEL: #{model_name}"

                begin
                    puts "Image: #{img}" 
                    tmi = TireModelInfo.find_by_tire_manufacturer_id_and_tire_model_name(manu.id, model_name)
                    if tmi.nil?
                        puts "*** INVALID TMI: #{model_name}"
                        invalid_tmi << model_name
                        tmi = TireModelInfo.new
                        tmi.tire_manufacturer_id = manu.id
                        tmi.tire_model_name = model_name
                        tmi.description = model_data.xpath("//div[@id='generalInfoArea']/p").text().strip()
                    else
                        puts "*** TMI EXISTS ***"
                    end
                    if tmi.photo1_url.nil? || tmi.photo1_url == ''
                        tmi.photo1_url = img
                        tmi.save if create_records
                    end
                rescue Exception => e
                    puts "ERROR #{e.to_s}"
                end

                odd = model_data.xpath("//table[@class='tblDetail']//tr[@class='rowOdd']")
                even = model_data.xpath("//table[@class='tblDetail']//tr[@class='rowEven']")
                (odd + even).each do |tire_size|
                    cols = tire_size.xpath("td")
                    m = /(\d{2,})\/(\d{2,}).*R(\d{2,})/.match(cols[1].text())
                    if m && m.size > 0
                        sizestr = m[0].gsub(/ZR/, 'R')

                        if cols.size == 10
                            tread_depth = cols[9].text().gsub(/\/32/, '')
                            tread_depth = "" if tread_depth == '/'

                            product_code = cols[0].text().strip().gsub(/^TP/, '').gsub(/^TL/, '')
                            sidewall = cols[3].text().strip()
                            load = cols[2].text().strip()
                            if !load || load == ""
                                load_index = ''
                                speed_rating = ''
                            else
                                load_index = load.scan(/\d/).join
                                speed_rating = load.scan(/\D/).join.gsub(/ XL/, '')
                                if speed_rating.include?("/")
                                    speed_rating = speed_rating[0]
                                end
                            end
                        else
                            puts "COLUMNS: #{cols.size}"
                        end
                        if speed_rating == "/"
                            speed_rating = ""
                        end

                        puts "SIZE: #{sizestr}"
                        puts "LI: #{load_index}"
                        puts "SPEED: #{speed_rating}"
                        puts "DEPTH: #{tread_depth}"
                        puts "SIDEWALL: #{sidewall}"
                        puts "PRODUCT: #{product_code}"

                        all_products << product_code

                        ts = TireSize.find_by_sizestr(sizestr)
                        if !ts 
                            puts "BAD SIZE: #{sizestr}"
                            invalid_size << sizestr
                        else
                            tm = TireModel.find_by_tire_manufacturer_id_and_tire_size_id_and_tire_model_info_id_and_product_code(manu.id, ts.id, tmi.id, product_code)
                            if tm
                                puts "*** ALREADY FOUND IT ***"
                            else
                                puts "*** HAVE TO CREATE IT ***"
                                tm = TireModel.new
                                tm.tire_manufacturer_id = manu.id
                                tm.tire_size_id = ts.id
                                tm.tire_model_info_id = tmi.id
                                tm.product_code = product_code
                            end
                            tm.load_index = load_index
                            tm.speed_rating = speed_rating
                            tm.tread_depth = tread_depth
                            tm.save if create_records
                        end
                    end
                end
            end
        end
        puts "*** SUMMARY ***"
        puts "Invalid TMI:"
        invalid_tmi.sort.each do |t|
            puts t 
        end

        puts "Invalid Size:"
        invalid_size.uniq.each do |s|
            puts s
        end

        puts "Products:"
        all_products.sort.each do |p|
            puts p 
        end
    end
end