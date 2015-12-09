require 'nokogiri'
require 'open-uri'

def ReadData(url)
    RestClient.get url#, :user_agent => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) "
    #open(url, :proxy => "http://54.243.138.45:80", "User-Agent" => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) ").read
end

namespace :ScrapeGremax do
    desc "Create tire manufacturers data from Gremax"
    task populate: :environment do
        tire_make = "Gremax"
        model_name = "Max 5000"

        manu = TireManufacturer.find_or_create_by_name(tire_make)

        model_url = "http://www.crowntyre.com/products/gremax/gremax-pcr/max_5000"
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
            #puts "#{model_response.to_s}"
            model_data.xpath("//tr").each do |tire_size|
                columns = tire_size.xpath(".//td")
                if columns && columns.size > 7
                    sizestr = columns[0].text().strip().gsub(/\*/, '')
                    utqg_treadwear = "420"
                    utqg_traction = "A"
                    utqg_temp = "A"
                    load = columns[1].text().strip()
                    if !load || load == ""
                        load_index = ''
                        speed_rating = ''
                    else
                        load_index = load.scan(/\d/).join
                        speed_rating = load.scan(/\D/).join.gsub(/XL/, '')
                        if load_index.size > 3
                            load_index = load_index[0..1]
                        end
                        if speed_rating.size > 2
                            speed_rating = speed_rating[0..1]
                        end
                    end

                    puts "SIZE: #{sizestr}"
                    puts "LI: #{load_index}"
                    puts "SPEED: #{speed_rating}"
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
                        tm.utqg_treadwear = utqg_treadwear
                        tm.utqg_temp = utqg_temp
                        tm.utqg_traction = utqg_traction
                        tm.save
                    end
                end
            end
        else
            puts "Could not read URL"
        end
    end
end

