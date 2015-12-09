require 'nokogiri'
require 'rest_client'

namespace :ScrapeBelleTire do
    desc "Get tire information from BelleTire.com"
    task populate: :environment do
        begin
            brand = "Kenda"
            manu = TireManufacturer.find_by_name(brand)
            if manu.nil?
                puts "Creating new manufacturer record for " + brand
                manu = TireManufacturer.new(:name => brand)
                manu.save
            end

            model = "Kenetica KR17"

            # Now scrape DiscountTires's product page to get list of sizes
            model_url = "http://www.belletire.com/tire-sizes/63436/kenda-kenetica-kr17"

            model_response = RestClient.get model_url, {:cookies => {:zipCode => "48101", :priceRegion => "RM", "ASP.NET_SessionId" => "yki3txo3ptzouz5jfebwupdx"}}
            html_model = Nokogiri::HTML(model_response.to_s)

            html_model.xpath("//h3[@class='resultTitle']/a").each do |size_href|
                size_url = size_href.attribute("href").text().strip
                size_response = RestClient.get("http://www.belletire.com#{size_url}", {:cookies => {:zipCode => "48101", :priceRegion => "RM", "ASP.NET_SessionId" => "yki3txo3ptzouz5jfebwupdx"}})
                html_size = Nokogiri::HTML(size_response.to_s)

                size = html_size.xpath("//tr/td[contains(@class, 'sizeHeader')]/../td[@class='column2']").text().strip()

                ar = size.scan(/(\d{2,})\/(\d{2,})R(\d{2,}).(\d{2,})(.)/)[0]

                if !ar
                    puts "*** could not parse #{size}"
                else
                    sizestr = "#{ar[0]}/#{ar[1]}R#{ar[2]}"
                    load_index = ar[3].strip()
                    speed_rating = ar[4].strip()

                    puts "SIZE: #{sizestr}"
                    ts = TireSize.find_by_sizestr(sizestr)
                    if !ts
                        puts "Skipping because #{sizestr} not found"
                    else
                        utqg = html_size.xpath("//tr/td[contains(@class, 'utqgHeader')]/../td[@class='column2']").text().strip()
                        ar = utqg.scan(/(\d{3,}) *(\D) *(\D)/)[0]
                        if !ar
                            puts "*** could not parse utqg #{utqg}"
                        else
                            puts "UTQG #{utqg}"
                            treadwear = ar[0]
                            traction = ar[1]
                            temp = ar[2]
                        end
                        sidewall = html_size.xpath("//tr/td[contains(@class, 'sidewallHeader')]/../td[@class='column2']").text().strip()
                        puts "SIDEWALL: #{sidewall}"

                        speed = html_size.xpath("//tr/td[contains(@class, 'speedHeader')]/../td[@class='column2']").text().strip()
                        ar = speed.scan(/(\D) -/)[0]
                        if !ar
                            puts "*** could not parse speed #{speed}"
                        else
                            speed_rating = ar[0]
                            puts "SPEEDRATING: #{speed_rating}"
                        end

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
                        puts "*********************************************"
                    end
                end
            end
        rescue Exception => e
            puts "**** ERROR PARSING PAGE " + e.message
        end
    end
end
