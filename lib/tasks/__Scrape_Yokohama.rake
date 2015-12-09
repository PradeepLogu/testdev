require 'nokogiri'
require 'open-uri'

def ReadData(url)
    RestClient.get url, :user_agent => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) "
    #open(url, :proxy => "http://54.243.138.45:80", "User-Agent" => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) ").read
end

def process_yokohama_data(create_records)
    invalid_sizes = []
    invalid_tmi = []

    manu = TireManufacturer.find_or_create_by_name("Yokohama")

    TireSize.find_or_create_by_sizestr('315/35R30')

    base_url = "http://www.yokohamatire.com/tires/consumer/"
    base_response = ''
    (1..5).each do |i|
        begin
            base_response = ReadData(base_url)
            break
        rescue Exception => e 
            puts "Error processing #{base_url}: #{e.to_s} - try again"
        end
    end
    if base_response != '' # there was no error
        base_data = Nokogiri::HTML(base_response.to_s)

        # this has more models though some are invalid.
        #base_data.xpath("//select[@name='marketing_tread_name']/option").each do |model_option|
        #    model_name = model_option.attribute('value').text.to_s() if model_option
        #    if model_name != ""
        #        puts model_name
        #    end
        #end

        base_data.xpath("//ul[@id='search_results']/li/div[@class='details']/div[@class='actions']").each do |model_data|
            model_name = model_data.xpath("div[@class='compare']/input").attribute('value').text().to_s
            model_url = "http://www.yokohamatire.com" + model_data.xpath("a[@class='learn_more']").attribute("href").text().to_s
                    
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

                sizes_and_counts = {}
                model_data.xpath("//tr[contains(@class, 'tiredata')]").each do |tire_size|
                    all_data = Nokogiri::HTML(tire_size.to_s).xpath(".//td")

                    size_and_load = all_data[0].text().strip()
                    ar = size_and_load.scan(/(\d{2,})\/(\d{2,})(R|ZR|RF)(\d{2,}).(\d{1,})\(*(\w*)\)*/)[0]

                    if ar
                        sizestr = "#{ar[0]}/#{ar[1]}R#{ar[3]}"
                        sizes_and_counts[sizestr] = 0 if sizes_and_counts[sizestr].nil?
                        sizes_and_counts[sizestr] += 1
                    end
                end         

                model_data.xpath("//tr[contains(@class, 'tiredata')]").each do |tire_size|
                    all_data = Nokogiri::HTML(tire_size.to_s).xpath(".//td")

                    size_and_load = all_data[0].text().strip()
                    ar = size_and_load.scan(/(\d{2,})\/(\d{2,})(R|ZR|RF)(\d{2,}).(\d{1,})\(*(\w*)\)*/)[0]

                    if !ar
                        puts model_url
                        puts "*** could not parse size #{size_and_load}"
                    else
                        sizestr = "#{ar[0]}/#{ar[1]}R#{ar[3]}"
                        load_index = "#{ar[4]}"
                        speed_rating = "#{ar[5]}"

                        product_code = all_data[1].text().strip()

                        utqg = all_data[3].text().strip()
                        utArray = utqg.split('/')
                        utqg_treadwear = utArray[0]
                        utqg_traction = utArray[1]
                        utqg_temp = utArray[2]

                        tread_depth = all_data[10].text().strip()
                        rim_width = all_data[5].text().strip()
                        sidewall = all_data[14].text().strip()

                        puts "PART: #{product_code}"
                        puts "SIZE: #{sizestr}"
                        puts "LI: #{load_index}"
                        puts "SPEED: #{speed_rating}"
                        puts "DEPTH: #{tread_depth}"
                        puts "TREADWEAR: #{utqg_treadwear}"
                        puts "TRACTION: #{utqg_traction}"
                        puts "TEMP: #{utqg_temp}"
                        puts "RIM: #{rim_width}"
                        puts "SIDEWALL: #{sidewall}"
                        puts "***************************"
                        
                        if sizes_and_counts[sizestr] > 1
                            multiples = true
                        else
                            multiples = false
                        end

                        tire_size = TireSize.find_by_sizestr(sizestr)
                        if !tire_size
                            invalid_sizes << sizestr if !invalid_sizes.include?(sizestr)
                        else
                            tire_model_info = TireModelInfo.where("tire_manufacturer_id = ? and tire_model_name ilike ?", manu.id, model_name).first
                            if tire_model_info.nil?
                                tire_model_info = TireModelInfo.new
                                tire_model_info.tire_manufacturer_id = manu.id
                                tire_model_info.tire_model_name = model_name
                                tire_model_info.save if create_records

                                puts "*** CREATING TMI RECORD FOR #{model_name}"
                                invalid_tmi << model_name if !invalid_tmi.include?(model_name)
                            end
                            if sizes_and_counts[sizestr] > 1
                                multiples = true
                            else
                                multiples = false
                            end

                            if multiples
                                puts "**** MULTIPLE"
                                tire_model = TireModel.find_by_tire_manufacturer_id_and_tire_size_id_and_tire_model_info_id_and_product_code(manu.id, tire_size.id, tire_model_info.id, product_code)                                
                            else
                                tire_model = TireModel.find_by_tire_manufacturer_id_and_tire_size_id_and_tire_model_info_id(manu.id, tire_size.id, tire_model_info.id)
                            end
                            if tire_model.nil?
                                tire_model = TireModel.new
                                tire_model.tire_manufacturer_id = manu.id
                                tire_model.tire_size_id = tire_size.id
                                tire_model.name = model_name

                                puts "*** CREATING Tire Model RECORD FOR #{model_name} #{sizestr}"
                            end

                            if !tire_model_info.stock_photo1.exists?
                                puts model_url
                                img_url = model_data.xpath('//div[@id="tire_detail_branding"]/ul/li[3]/a/@href').text().strip()
                                img_url = model_data.xpath('//div[@id="tire_detail_branding"]/ul/li[2]/a/@href').text().strip() if img_url.nil? || img_url.blank?
                                if !img_url.nil?
                                    tire_model_info.photo1_url = img_url
                                end
                                puts "**** NO PHOTO: #{tire_model_info.photo1_url}"
                            end

                            tire_model_info.save if create_records

                            tire_model.tire_model_info_id = tire_model_info.id

                            tire_model.load_index = load_index
                            tire_model.speed_rating = speed_rating
                            tire_model.tread_depth = tread_depth
                            tire_model.utqg_treadwear = utqg_treadwear
                            tire_model.utqg_temp = utqg_temp
                            tire_model.utqg_traction = utqg_traction
                            tire_model.rim_width = rim_width
                            tire_model.sidewall = sidewall
                            tire_model.product_code = product_code

                            tire_model.save if create_records
                        end
                    end
                end
            end
        end
        puts "**** EXCEPTION REPORT ****"
        puts "Invalid sizes: "
        puts "\t" + invalid_sizes.join("\n\t")
        puts ""
        puts "Invalid TMI: "
        puts "\t" + invalid_tmi.join("\n\t")
    end    
end

namespace :ScrapeYokohama do
    desc "Create tire manufacturers data from Yokohama"
    task populate: :environment do
        process_yokohama_data(true)
    end

    task test: :environment do 
        process_yokohama_data(false)
    end
end

