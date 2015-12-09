require 'nokogiri'
require 'open-uri'

def ReadData(url)
    RestClient.get url, :user_agent => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) "
    #open(url, :proxy => "http://54.243.138.45:80", "User-Agent" => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) ").read
end

namespace :ScrapeDuro do
    desc "Create tire manufacturers data from Duro"
    task populate: :environment do
        tire_make = "Duro"
        manu = TireManufacturer.find_or_create_by_name(tire_make)

        TireSize.find_or_create_by_sizestr('195/60R16')
        TireSize.find_or_create_by_sizestr('185/65R16')

        all_models_response = ""
        all_models_url = "http://www.durotire.com/tires/tabid/186/categoryid/1/default.aspx"
        (1..5).each do |i|
            begin
                all_models_response = ReadData(all_models_url)
                break
            rescue Exception => e 
                puts "Error processing #{all_models_url}: #{e.to_s} - try again"
            end
        end

        if all_models_response != ""
            all_models_data = Nokogiri::HTML(all_models_response.to_s)
            all_models_data.xpath("//input[@class='btn' and @value='View Details']").each do |tire_model|
                model_url = 'http://www.durotire.com' + tire_model.attribute('onclick').text().gsub(/parent\.location/, '').gsub(/'/, '').gsub(/\=/, '')
                puts "#{model_url}"
                model_response = ReadData(model_url)
                model_data = Nokogiri::HTML(model_response.to_s)
                model_name = model_data.xpath("//h1").text().strip()
                puts "MODEL: #{model_name}"
                model_data.xpath("//tr[@class='telerik-reTableOddRow-1' or @class='telerik-reTableEvenRow-1']").each do |row|
                    ar = row.xpath(".//td")
                    bad_record = false
                    nbsp = Nokogiri::HTML("&nbsp;").text
                    case ar.size
                        when 9
                            sizestr = ar[0].text().strip().gsub(/ZR/, 'R').gsub(/XL/, '').gsub(/-/, '/').gsub(/ /, '').gsub(nbsp, '')
                            service = ar[1].text().strip()
                            rim_width = ar[2].text().strip()
                            tread_depth = ar[5].text().strip().gsub(/\/32/, '')
                            utqg_treadwear = ar[6].text().strip()
                            utqg_traction = ar[7].text().strip()
                            utqg_temp = ar[8].text().strip()
                        when 5
                            sizestr = ar[0].text().strip().gsub(/ZR/, 'R').gsub(/XL/, '').gsub(/-/, '/').gsub(/ /, '').gsub(nbsp, '')
                            service = ar[1].text().strip()
                            rim_width = ar[2].text().strip()
                            tread_depth = ''
                            utqg_treadwear = ''
                            utqg_traction = ''
                            utqg_temp = ''
                        when 6
                            sizestr = ar[0].text().strip().gsub(/ZR/, 'R').gsub(/XL/, '').gsub(/-/, '/').gsub(/ /, '').gsub(nbsp, '')
                            service = ar[1].text().strip()
                            rim_width = ar[2].text().strip()
                            tread_depth = ar[5].text().strip().gsub(/\/32/, '')
                            utqg_treadwear = ''
                            utqg_traction = ''
                            utqg_temp = ''
                        else
                            sizestr = ar[0]
                            bad_record = true
                    end
                    if bad_record
                        puts "*** UNABLE TO PROCESS " + row.xpath('.//td').text().strip()
                    else
                        ts = TireSize.find_by_sizestr(sizestr)
                        if !ts 
                            puts "*** UNABLE TO FIND *#{sizestr}*"
                        else
                            a = service.scan(/(\d{2,})(\D).*/)[0]
                            load_index = a[0]
                            speed_rating = a[1]
                            puts "LOAD: #{load_index}"
                            puts "SPEED: #{speed_rating}"
                            puts "SIZE: #{sizestr}"
                            puts "RIM: #{rim_width}"
                            puts "DEPTH: #{tread_depth}"
                            puts "TREAD: #{utqg_treadwear}"
                            puts "TRACT: #{utqg_traction}"
                            puts "TEMP: #{utqg_temp}"

                            tm = TireModel.find_or_create_by_tire_manufacturer_id_and_tire_size_id_and_name(manu.id, ts.id, model_name)
                            tm.load_index = load_index
                            tm.speed_rating = speed_rating
                            #tm.sidewall = sidewall
                            tm.rim_width = rim_width
                            tm.tread_depth = tread_depth
                            tm.utqg_temp = utqg_temp
                            tm.utqg_traction = utqg_traction
                            tm.utqg_treadwear = utqg_treadwear
                            tm.save
                        end
                    end
                end
            end
        end
    end
end



namespace :ScrapeNitto do
    desc "Create tire manufacturers data from Nitto"
    task populate: :environment do
        all_models_response = ""
        all_models_url = "https://www.nittotire.com/TireSelector/Category?tireSection=street"
        (1..5).each do |i|
            begin
                all_models_response = ReadData(all_models_url)
                break
            rescue Exception => e 
                puts "Error processing #{all_models_url}: #{e.to_s} - try again"
            end
        end

        manu = TireManufacturer.find_by_name("Nitto")

        if all_models_response != ""
            #puts all_models_response.to_s
            all_models_data = Nokogiri::HTML(all_models_response.to_s)

            myJSON = "{" + /data\ =\ \{(.*)\}/.match(all_models_response.to_s)[1] + "}"

            j = JSON.parse(myJSON)

            j["Tires"].each do |tire|
                @tire_model_name = tire["DisplayName"]
                @tire_model_image_url = "http://www.nittotire.com" + tire["ThumbnailUrl"]
                @tire_model_url = "http://www.nittotire.com" + tire["TireUrl"]

                puts @tire_model_name
                puts @tire_model_image_url

                tire_details_response = ""
                (1..5).each do |i|
                    begin
                        tire_details_response = ReadData(@tire_model_url)
                        break
                    rescue Exception => e 
                        puts "Error processing #{tire_model_url}: #{e.to_s} - try again"
                    end
                end

                @utqg_treadwear = ""
                @utqg_traction = ""
                @utqg_temp = ""
                @model_description = ""
                if tire_details_response != ""
                    tire_details_data = Nokogiri::HTML(tire_details_response.to_s)
                    @utqg_info = tire_details_data.xpath("//p[contains(., 'UTQG Treadwear:')]").text().strip()
                    puts "UTQG INFO: #{@utqg_info}"
                    begin
                        @utqg_treadwear = /UTQG Treadwear:\ (\d*).*/.match(@utqg_info)[1]
                    rescue
                    end

                    begin
                        @utqg_traction = /.*Traction:*\ (\w).*/.match(@utqg_info)[1]
                    rescue
                    end

                    begin
                        @utqg_temp = /.*Temperature:*\ (\w).*/.match(@utqg_info)[1]
                    rescue
                    end

                    tire_details_data.xpath("//p[@class='p1']").each do |det|
                        @model_description += det.text().strip() + "<br/>"
                        puts "********"
                        puts @model_description
                    end
                end

                tire["Groups"].each do |tire_details|
                    details_array = tire_details["Details"]
                    details_array.each do |tire_size|
                        @tire_size_full = tire_size["TireSize"]
                        @product_code = tire_size["ProductCode"]
                        @tread_depth = tire_size["TreadDepth"]
                        @speed_rating = tire_size["SpeedRating"]
                        @width = tire_size["OverallWidth"]
                        #@load = tire_size["Load"]

                        ar = /.*(\d{3})\/(\d{2})(.*)R(\d{2}) (\d{2,3})/.match(@tire_size_full)
                        @tire_size = "#{ar[1]}/#{ar[2]}R#{ar[4]}"
                        @tire_code = ar[3]
                        @load = ar[5]

                        @ts = TireSize.find_or_create_by_sizestr(@tire_size)

                        @tire_model = TireModel.find(:first, :conditions => ["tire_manufacturer_id = ? and tire_size_id = ? and lower(name) = ?", manu.id, @ts.id, @tire_model_name.downcase])
                        if @tire_model.nil?
                            @tire_model = TireModel.new
                            @tire_model.tire_manufacturer_id = manu.id
                            @tire_model.tire_size_id = @ts.id
                            @tire_model.name = @tire_model_name
                            puts "Creating new #{@tire_model_name} #{@ts.sizestr}"
                        else
                            @tire_model.name = @tire_model_name
                            puts "Updating #{@tire_model_name} #{@ts.sizestr}"
                        end

                        @tire_model.tire_code = @tire_code
                        @tire_model.manu_part_num = @product_code
                        @tire_model.product_code = @product_code
                        @tire_model.tread_depth = @tread_depth
                        @tire_model.speed_rating = @speed_rating
                        @tire_model.load_index = @load
                        @tire_model.utqg_temp = @utqg_temp
                        @tire_model.utqg_treadwear = @utqg_treadwear
                        @tire_model.utqg_traction = @utqg_traction
                        @tire_model.save

                        begin
                            @tire_model_info = TireModelInfo.find(@tire_model.tire_model_info_id)
                        rescue
                            @tire_model_info = nil
                        end
                        if !@tire_model_info.nil? && @tire_model_info.photo1_url.blank?
                            @tire_model_info.photo1_url = @tire_model_image_url
                            @tire_model_info.description = @model_description
                            @tire_model_info.save
                        end
                        puts "--------------------------"
                    end
                end
            end

            all_models_data.xpath("//div[contains(@class,'tire_img')]").each do |tire_model|
                puts "dude"
                model_img_url = "www.nittotire.com" + tire_model.xpath("a[2]/img/@src").text().strip()
                puts model_img_url
            end
        end
    end
end