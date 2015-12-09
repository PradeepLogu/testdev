require 'nokogiri'
require 'open-uri'

def ReadData(url)
    RestClient.get url, :user_agent => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) "
    #open(url, :proxy => "http://54.243.138.45:80", "User-Agent" => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) ").read
end

namespace :ScrapeOhtsu do
    desc "Create tire manufacturers data from Ohtsu"
    task populate: :environment do
        tire_make = "Ohtsu"
        model_name = "FP7000"

        manu = TireManufacturer.find_or_create_by_name(tire_make)

        model_url = "http://www.ohtsutires.com/Tires-Detail/FP7000/23"
        model_response = ''
        (1..5).each do |i|
            begin
                model_response = ReadData(model_url)
                break
            rescue Exception => e 
                puts "Error processing #{model_url}: #{e.to_s} - try again"
            end
        end
        if model_response != '' # there was no error
            model_data = Nokogiri::HTML(model_response.to_s)
            model_data.xpath("//div[@class='specs-row' or @class='specs-row-alt']").each do |tire_size|
                sizestr = tire_size.xpath('.//div')[0].text().strip()
                utqg = tire_size.xpath('.//div')[1].text().strip()
                utArray = utqg.split('-')
                utqg_treadwear = utArray[0]
                utqg_traction = utArray[1]
                utqg_temp = utArray[2]
                load = tire_size.xpath('.//div')[2].text().strip()
                if !load || load == ""
                    load_index = ''
                    speed_rating = ''
                else
                    load_index = load.scan(/\d/).join
                    speed_rating = load.scan(/\D/).join.gsub(/ XL/, '')
                end
                tread_depth = tire_size.xpath('.//div')[10].text().strip().gsub(/\/32/, '')

                puts "SIZE: #{sizestr}"
                puts "LI: #{load_index}"
                puts "SPEED: #{speed_rating}"
                puts "DEPTH: #{tread_depth}"
                puts "TREADWEAR: #{utqg_treadwear}"
                puts "TRACTION: #{utqg_traction}"
                puts "TEMP: #{utqg_temp}"

                ts = TireSize.find_by_sizestr(sizestr)
                if !ts 
                    puts "BAD SIZE: #{sizestr}"
                else
                    tm = TireModel.find_or_create_by_tire_manufacturer_id_and_tire_size_id_and_name(manu.id, ts.id, model_name)
                    tm.load_index = load_index
                    tm.speed_rating = speed_rating
                    tm.tread_depth = tread_depth
                    tm.utqg_treadwear = utqg_treadwear
                    tm.utqg_temp = utqg_temp
                    tm.utqg_traction = utqg_traction
                    tm.save
                end
            end
        end
    end
end


namespace :ScrapeNankang do
    desc "Create tire manufacturers data from Nankang"
    task populate: :environment do
        tire_make = "Nankang"
        manu = TireManufacturer.find_or_create_by_name(tire_make)

        TireSize.find_or_create_by_sizestr("165/70R12")
        TireSize.find_or_create_by_sizestr("215/50R18")

        tire_line_urls = [
                            "http://nankangusa.com/tires/performance",
                            "http://nankangusa.com/tires/rltsuv",
                            "http://nankangusa.com/tires/touring"
                        ]

        tire_line_urls.each do |tl_Url|
            tl_response = ''
            (1..5).each do |i|
                begin
                    tl_response = ReadData(tl_Url)
                    break
                rescue Exception => e 
                    puts "Error processing #{tl_Url}: #{e.to_s} - try again"
                end
            end
            if tl_response != '' # there was no error
                tl_data = Nokogiri::HTML(tl_response.to_s)
                tl_data.xpath("//div[@id='tires-teaser']").each do |model_info|
                    model_name = model_info.xpath(".//h2").text().strip()
                    puts "#{model_name}"

                    model_url = "http://nankangusa.com" + model_info.attribute("onclick").text().gsub(/location.href=/, '').gsub(/'/, '') + "?tab=specs"
                    puts "#{model_url}"

                    model_response = ""
                    (1..5).each do |j|
                        begin
                            model_response = ReadData(model_url)
                            break
                        rescue Exception => e 
                            puts "Error processing #{model_url}: #{e.to_s} - try again"
                        end
                    end
                    if model_response != ''
                        model_data = Nokogiri::HTML(model_response.to_s)
                        model_data.xpath("//table[@id='tablefield-0']/tbody/tr").each do |size|
                            #puts size.text
                            cols = size.xpath(".//td")
                            s = /(\d{2,})\/(\d{2,})R(\d{2,})/.match(cols[0].text())
                            if s
                                sizestr = s[0]
                                ts = TireSize.find_by_sizestr(sizestr)
                                if !ts
                                    puts "Invalid size: #{sizestr}"
                                else
                                    service_index = cols[1].text().strip()
                                    if service_index == sizestr
                                        puts "*** SKIPPING load because page is weird"
                                    else
                                        load_index = service_index.scan(/\d/).join
                                        speed_rating = service_index.scan(/\D/).join.gsub(/\//, '')

                                        load_index = load_index[0..2]
                                    end

                                    sidewall = cols[2].text().strip()

                                    utqg = cols.last.text().strip()

                                    if utqg.include?(".")
                                        puts "SKIPPING UTQG because page is weird"
                                    else
                                        if utqg.include?("AAA")
                                            utqg_treadwear = utqg.gsub(/AAA/, '')
                                            utqg_traction = "AA"
                                            utqg_temp = "A"
                                        elsif utqg.include?("AA")
                                            utqg_treadwear = utqg.gsub(/AA/, '')
                                            utqg_traction = "A"
                                            utqg_temp = "A"
                                        end
                                    end

                                    puts "SIZE: #{sizestr}"
                                    puts "LOAD: #{load_index}"
                                    puts "SPEED: #{speed_rating}"
                                    puts "SIDE: #{sidewall}"
                                    puts "TRED: #{utqg_treadwear}"
                                    puts "TRAC: #{utqg_traction}"
                                    puts "TEMP: #{utqg_temp}"

                                    tm = TireModel.find_or_create_by_tire_manufacturer_id_and_tire_size_id_and_name(manu.id, ts.id, model_name)
                                    tm.load_index = load_index
                                    tm.speed_rating = speed_rating
                                    tm.sidewall = sidewall
                                    tm.utqg_treadwear = utqg_treadwear
                                    tm.utqg_temp = utqg_temp
                                    tm.utqg_traction = utqg_traction
                                    tm.save
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end