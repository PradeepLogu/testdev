require 'nokogiri'
require 'rest_client'

namespace :ScrapeDiscountTire do
    desc "Get tire information from DiscountTire.com"
    task populate: :environment do
        begin
            brand = "Barum"
            manu = TireManufacturer.find_by_name(brand)
            if manu.nil?
                puts "Creating new manufacturer record for " + brand
                manu = TireManufacturer.new(:name => brand)
                manu.save
            end

            model = "Bravuris 2"

            # Now scrape DiscountTires's product page to get list of sizes
            model_url = "http://www.discounttire.com/dtcs/tires/barum/product/byName.do?tmn=Bravuris+2&typ=Passenger%2FPerformance&postalCodeSelected=30564"

            model_response = RestClient.get model_url
            html_model = Nokogiri::HTML(model_response.to_s)

            html_model.xpath("//li[@class='sizeListSpecialfalse']/a").each do |size_href|
                size_url = size_href.attribute("href").text().strip
                size_response = RestClient.get("http://www.discounttire.com#{size_url}")
                html_size = Nokogiri::HTML(size_response.to_s)

                size = html_size.xpath("//p[@class='detailSize']").text().strip()

                ar = size.scan(/(\d{2,})\/(\d{2,}).*R.*(\d{2,}).* (\d{2,})(\D)(\D{2,})/)[0]

                if !ar
                    puts "*** could not parse #{size}"
                else
                    sizestr = "#{ar[0]}/#{ar[1]}R#{ar[2]}"
                    sidewall = ar[5].strip()
                    load_index = ar[3].strip()
                    speed_rating = ar[4].strip()

                    puts "SIZE: #{sizestr}"
                    ts = TireSize.find_by_sizestr(sizestr)
                    if !ts
                        puts "Skipping because #{sizestr} not found"
                    else
                        treadwear = html_size.xpath("//td[@class='attributeValue']")[0].text().strip
                        traction = html_size.xpath("//td[@class='attributeValue']")[1].text().strip
                        temp = html_size.xpath("//td[@class='attributeValue']")[2].text().strip
                        # I don't think this speed rating is right
                        #speed_rating = html_size.xpath("//td[@class='attributeValue']")[3].text().strip

                        sidewall = ''
                        puts "SIDEWALL: #{sidewall}"
                        puts "SPEEDRATING: #{speed_rating}"
                        puts "LOAD: #{load_index}"

                        puts "TREADWEAR: #{treadwear}"
                        puts "TRACTION: #{traction}"
                        puts "TEMP: #{temp}"

                        tm = TireModel.find_or_create_by_tire_manufacturer_id_and_tire_size_id_and_name(manu.id, ts.id, model)
                        #tm = TireModel.new
                        tm.load_index = load_index
                        tm.speed_rating = speed_rating
                        tm.utqg_temp = temp
                        tm.utqg_treadwear = treadwear
                        tm.utqg_traction = traction

                        tm.sidewall = sidewall
                        tm.name = model
                        tm.save()
                    end
                end
            end
        rescue Exception => e
            puts "**** ERROR PARSING PAGE " + e.message
        end
    end
end
