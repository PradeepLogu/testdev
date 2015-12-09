require 'nokogiri'
require 'open-uri'

def ReadData(url)
    RestClient.get url, :user_agent => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) "
    #open(url, :proxy => "http://54.243.138.45:80", "User-Agent" => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) ").read
end

namespace :ScrapeWestlake do
    desc "Create tire manufacturers data from Westlake"
    task populate: :environment do
        tire_make = "Westlake"

        TireSize.find_or_create_by_sizestr("165/60R14")
        TireSize.find_or_create_by_sizestr("165/70R14")
        TireSize.find_or_create_by_sizestr("175/80R14")
        TireSize.find_or_create_by_sizestr("185/80R14")
        TireSize.find_or_create_by_sizestr("215/80R16")
        TireSize.find_or_create_by_sizestr("175/60R13")
        TireSize.find_or_create_by_sizestr("175/60R14")
        TireSize.find_or_create_by_sizestr("175/60R15")
        TireSize.find_or_create_by_sizestr("245/80R16")
        TireSize.find_or_create_by_sizestr("175/75R16")
        TireSize.find_or_create_by_sizestr("205/75R16")
        TireSize.find_or_create_by_sizestr("195/75R16")
        TireSize.find_or_create_by_sizestr("195/65R16")

        manu = TireManufacturer.find_or_create_by_name(tire_make)

        model_urls = [
                        "http://www.westlaketire.com/en/car-and-minivan-tires/84-sp06",
                        "http://www.westlaketire.com/en/car-and-minivan-tires/70-h210",
                        "http://www.westlaketire.com/en/car-and-minivan-tires/74-h260",
                        "http://www.westlaketire.com/en/car-and-minivan-tires/77-h550a",
                        "http://www.westlaketire.com/en/car-and-minivan-tires/383-rp09",
                        "http://www.westlaketire.com/en/car-and-minivan-tires/382-rp26",
                        "http://www.westlaketire.com/en/car-and-minivan-tires/384-rp19",
                        "http://www.westlaketire.com/en/high-performance-tires/65-sa05",
                        "http://www.westlaketire.com/en/high-performance-tires/62-sv308",
                        "http://www.westlaketire.com/en/high-performance-tires/381-sa07",
                        "http://www.westlaketire.com/winter-tires/323-sw606",
                        "http://www.westlaketire.com/winter/69-sw601",
                        "http://www.westlaketire.com/winter/66-sw602",
                        "http://www.westlaketire.com/winter/328-sw608",
                        "http://www.westlaketire.com/winter/329-sw612",
                        "http://www.westlaketire.com/en/suv-and-crossover/330-sv308",
                        "http://www.westlaketire.com/en/suv-and-crossover/63-su307",
                        "http://www.westlaketire.com/en/suv-and-crossover/331-su317",
                        "http://www.westlaketire.com/trucks-light-truck-radial-tires/333-sl309",
                        "http://www.westlaketire.com/en/trucks-light-truck-radial-tires/335-sl369",
                        "http://www.westlaketire.com/en/trucks-light-truck-radial-tires/334-sl325",
                        "http://www.westlaketire.com/en/trucks-light-truck-radial-tires/332-cr857",
                        #"http://www.westlaketire.com/en/trucks-light-truck-radial-tires/246-sl306",
                        "http://www.westlaketire.com/en/trucks-light-truck-radial-tires/242-h170",
                        "http://www.westlaketire.com/en/trucks-light-truck-radial-tires/245-sc301",
                        "http://www.westlaketire.com/en/trucks-light-truck-radial-tires/385-sl305",
                        "http://www.westlaketire.com/en/trucks-light-truck-radial-tires/386-sc328"
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

                model_name = model_data.xpath("//span[@class='prodsub-model']").text.strip()
                img = model_data.xpath(".//img[@class='prod-detail']")
                    
                puts "MODEL: #{model_name}"

                begin
                    puts "Image: #{img.attribute('src')}" 
                    tmi = TireModelInfo.find_or_create_by_tire_manufacturer_id_and_tire_model_name(manu.id, model_name)
                    if tmi.photo1_url.nil? || tmi.photo1_url == ''
                        tmi.photo1_url = "http://www.westlaketire.com#{img.attribute('src')}"
                        tmi.save
                    end
                rescue Exception => e
                    puts "ERROR #{e.to_s}"
                end

                model_data.xpath("//table[@class='specs']//tbody/tr").each do |tire_size|
                    cols = tire_size.xpath(".//td")
                    m = /(\d{2,})\/(\d{2,}).*R(\d{2,})/.match(cols[0].text())
                    if m && m.size > 0
                        sizestr = m[0].gsub(/ZR/, 'R')

                        if cols.size == 16
                            tread_depth = cols[4].text()
                            tread_depth = "" if tread_depth == '/'

                            load = cols[5].text().strip()
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
                        elsif cols.size == 14
                            tread_depth = cols[3].text()
                            tread_depth = "" if tread_depth == '/'

                            load = cols[4].text().strip()
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
                        elsif cols.size == 12
                            tread_depth = cols[3].text()
                            tread_depth = "" if tread_depth == '/'

                            load = cols[4].text().strip()
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
                        elsif cols.size == 13
                            tread_depth = cols[3].text()
                            tread_depth = "" if tread_depth == '/'

                            load = cols[4].text().strip()
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
                        elsif cols.size == 15
                            tread_depth = cols[3].text()
                            tread_depth = "" if tread_depth == '/'

                            load = cols[4].text().strip()
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
                        
                        if load_index.size > 3
                            load_index = load_index[0..2]
                        end
                        if speed_rating == "/"
                            speed_rating = ""
                        end

                        puts "SIZE: #{sizestr}"
                        puts "LI: #{load_index}"
                        puts "SPEED: #{speed_rating}"
                        puts "DEPTH: #{tread_depth}"

                        ts = TireSize.find_by_sizestr(sizestr)
                        if !ts 
                            puts "BAD SIZE: #{sizestr}"
                        else
                            tm = TireModel.find_or_create_by_tire_manufacturer_id_and_tire_size_id_and_name(manu.id, ts.id, model_name)
                            tm.load_index = load_index
                            tm.speed_rating = speed_rating
                            tm.tread_depth = tread_depth
                            tm.save
                        end
                    end
                end
            end
        end
    end
end