require 'nokogiri'
require 'open-uri'


def ReadData(url)
    RestClient.get url, :user_agent => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) "
    #open(url, :proxy => "http://54.243.138.45:80", "User-Agent" => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) ").read
end

namespace :ScrapeTireIntel do
    desc "Create tire manufacturers data from TireIntel"
    task populate: :environment do
        tire_make = "Milestar"
        model_name = "SL309"

        manu = TireManufacturer.find_or_create_by_name(tire_make)

        model_url = "http://www.tireintel.com/tire/MILE/22860010"
        model_response = ''
        (1..5).each do |i|
            begin
                model_response = ReadData(model_url)
                break
            rescue Exception => e 
                puts "Error processing #{model_url}: #{e.to_s} - try again"
            end
        end

        nbsp = Nokogiri::HTML("&nbsp;").text

        if model_response != '' # there was no error
            model_data = Nokogiri::HTML(model_response.to_s)
            model_data.xpath('//table[@class="specifications"]//tr[td]').each do |tire_size|
                columns = tire_size.xpath(".//td")
                if columns.size > 9
                    size = /(\d{2,})\/(\d{2,})R(\d{2,})/.match(columns[1].text())
                    if size
                        sizestr = size[0]
                        load_index = columns[2].text().strip()
                        speed_rating = columns[3].text().strip()
                        sidewall = columns[4].text().strip()
                        utArray = columns[6].text().strip().gsub(nbsp, " ").split(' ')
                        utqg_treadwear = utArray[0]
                        utqg_traction = utArray[1]
                        utqg_temp = utArray[2]

                        puts "SIZE: #{sizestr}"
                        puts "LI: #{load_index}"
                        puts "SPEED: #{speed_rating}"
                        puts "TRACTION: #{utqg_traction}"
                        puts "TEMP: #{utqg_temp}"
                        puts "TREADWEAR: #{utqg_treadwear}"
                        puts "SIDEWALL: #{sidewall}"

                        ts = TireSize.find_by_sizestr(sizestr)
                        if !ts 
                            puts "BAD SIZE: #{sizestr}"
                        else
                            tm = TireModel.find_or_create_by_tire_manufacturer_id_and_tire_size_id_and_name(manu.id, ts.id, model_name)
                            tm.load_index = load_index
                            tm.speed_rating = speed_rating
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