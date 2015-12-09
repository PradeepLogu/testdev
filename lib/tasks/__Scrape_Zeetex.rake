require 'nokogiri'
require 'open-uri'

def ReadData(url)
    RestClient.get url, :user_agent => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) "
    #open(url, :proxy => "http://54.243.138.45:80", "User-Agent" => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) ").read
end

namespace :ScrapeZeetex do
    desc "Create tire manufacturers data from Zeetex"
    task populate: :environment do
        tire_make = "Zeetex"

        manu = TireManufacturer.find_or_create_by_name(tire_make)

        manu_url = "http://zeetex.com/products.php?scatid=1&catid=1"
        manu_response = ''
        (1..5).each do |i|
            begin
                manu_response = ReadData(manu_url)
                break
            rescue Exception => e 
                puts "Error processing #{manu_url}: #{e.to_s} - try again"
            end
        end
        if manu_response != ''
            manu_data = Nokogiri::HTML(manu_response.to_s)

            manu_data.xpath("//a[contains(@href, 'prodpattern')]").each do |tire_model|
                if tire_model.text().strip == ''
                    img = tire_model.xpath(".//img")
                    puts tire_model.to_html
                    model_name = tire_model.attribute('title').text().strip()
                    puts "Model: #{model_name}"
                    puts "Image: #{img.attribute('src')}"

                    tmi = TireModelInfo.find_or_create_by_tire_manufacturer_id_and_tire_model_name(manu.id, model_name)
                    #if tmi.photo1_url.nil? || tmi.photo1_url == ''
                    #    tmi.photo1_url = "#{img.attribute('src')}"
                    #    tmi.save
                    #end

                    model_url = "http://zeetex.com/" + tire_model.attribute('href')
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
                        model_data.xpath("//tr[@class='colbksmall' or @class='colbk1small']").each do |tire_size|
                            sizestr = tire_size.xpath('.//td')[0].text().gsub(/ZR/, 'R').gsub(/ R/, 'R')
                            load = tire_size.xpath('.//td')[1].text().strip()
                            if !load || load == ""
                                load_index = ''
                                speed_rating = ''
                            else
                                load_index = load.scan(/\d/).join
                                speed_rating = load.scan(/\D/).join.gsub(/ XL/, '')
                            end
                            tread_depth = tire_size.xpath('.//td')[9].text().strip()
                            utqg = tire_size.xpath('.//td')[10].text().strip()
                            utArray = utqg.split(' ')
                            utqg_treadwear = utArray[0]
                            utqg_traction = utArray[1]
                            utqg_temp = utArray[2]

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
        end

        #tire_model = "Sigma"

        #model_url = "http://www.performanceplustire.com/tires-for-sale/#{tire_make}-tires/#{tire_model}".downcase()
        #model_url = URI::encode(model_url)
        #puts "Reading #{model_url}..."
        #model_response = ''
        #(1..5).each do |i|
        #    begin
        #        model_response = ReadData(model_url)
        #        break
        #    rescue Exception => e 
        #        puts "Error processing #{model_url}: #{e.to_s} - try again"
        #    end
        #end
        #if model_response != '' # there was no error
        #    html_data = Nokogiri::HTML(model_response.to_s)

        #    html_data.xpath("//div[@class='productDetailRow']").each do |tire_size|
        #        manu = TireManufacturer.find_or_create_by_name(tire_make)

        #        specs = tire_size.xpath(".//td[@class='productDetailData']")[1]
        #        s1 = specs.xpath(".//strong")[0].text()
        #        s2 = specs.xpath(".//strong")[1].text()
        #        s3 = specs.xpath(".//strong")[2].text()
        #        s4 = specs.xpath(".//strong")[3].text()
        #        s5 = specs.xpath(".//strong")[4].text()
        #        s6 = specs.xpath(".//strong")[5].text()

        #        if s2 == "BLACK"
        #            s2 = "BW"
        #        end

        #        sizestr = tire_size.xpath(".//td[@class='productDetailData']")[0].text().strip().split(' ')[0].gsub(/ZR/, 'R')
        #        load = tire_size.xpath(".//td[@class='productDetailData']")[0].text().strip().split(' ')[1]
        #        if !load || load == ""
        #            load_index = ''
        #            speed_rating = ''
        #        else
        #            load_index = load.scan(/\d/).join
        #            speed_rating = load.scan(/\D/).join
        #        end
        #        puts "Size: #{sizestr}"
        #        puts "Load: #{load_index}"
        #        puts "Speed: #{speed_rating}"
        #        #puts "Specs: #{specs.text()}"
        #        puts "Sidewall: #{s2}"
        #        puts "UTQG: #{s6}"
        #        unless s6 == '-' || s6 == '' || s6 == 'N/A'
        #            utArray = s6.split('-')
        #            utqg_treadwear = utArray[0]
        #            utqg_traction = utArray[1]
        #            utqg_temp = utArray[2]
        #        else
        #            utqg_treadwear = 
        #            utqg_traction = ''
        #            utqg_temp = ''
        #        end

        #        ts = TireSize.find_by_sizestr(sizestr)
        #        if !ts 
        #            puts "Unable to find size #{sizestr}"
        #        else
        #            tm = TireModel.find_or_create_by_tire_manufacturer_id_and_tire_size_id_and_name(manu.id, ts.id, tire_model)
        #            tm.load_index = load_index
        #            tm.speed_rating = speed_rating
        #            tm.sidewall = s2
        #            tm.utqg_temp = utqg_temp
        #            tm.utqg_traction = utqg_traction
        #            tm.utqg_treadwear = utqg_treadwear
        #            tm.save
        #        end
        #    end
        #else
        #    puts "Unable to read URL: #{model_url}.  Please check this URL to see if make and model were entered correctly."
        #end
    end
end