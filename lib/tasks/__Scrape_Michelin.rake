require 'nokogiri'
require 'open-uri'

def ReadData(url)
    RestClient.get url#, :user_agent => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) "
    #open(url, :proxy => "http://54.243.138.45:80", "User-Agent" => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) ").read
end

namespace :SetTireModelInfo do
    desc "Update tire model table with TireModelInfoId"
    task fix: :environment do
        models = TireModel.find_all_by_tire_model_info_id(-1)
        models.each do |m|
            m.save
        end
    end
end

def process_michelin_data(create_records)
    invalid_sizes = []
    invalid_tmi = []

    TireSize.find_or_create_by_sizestr('235/30R19')
    TireSize.find_or_create_by_sizestr('305/25R21')
    TireSize.find_or_create_by_sizestr('245/30R21')

    base_url = "http://www.michelinman.com"
    base_response = ""
    (1..5).each do |i|
        begin
            base_response = ReadData(base_url)
            break
        rescue Exception => e 
            puts "Error processing #{base_url}: #{e.to_s} - try again"
        end
    end
    if base_response != '' # there was no error
        # find all instances of "tire_name.push"
        ar1 = base_response.to_s.scan(/tire_name.push\(\"(.+)\"\)/)

        manu = TireManufacturer.find_or_create_by_name('Michelin')

        ar1.each do |model_names|
            model_name = model_names.first
            break if model_name == "Can't Find Your Tire Name?"

            model_url = "http://www.michelinman.com/michelincom/home.page?submit=true&componentID=1311657766888&iwPreActions=searchVehicle&Select+Tire+Name=#{URI::encode(model_name)}&searchType=name"
            puts "***************** #{model_url}"
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

                frozen_table_rows = model_data.xpath("//table[@class='frozen']//tr[@class='datarow ']")
                sliding_table_rows = model_data.xpath("//table[@class='head']//tr[contains(@class, 'datarow')]")

                # 07/02/13 ksi
                # This is a bit of a PITA.  As it turns out, there may be MANY (ie 6+) different
                # manu codes for the same size in the same model.  So we cannot assume a single
                # model record per size record.  If we have multiples, we'll have to have different
                # model/tiremodelinfo records to differentiate.
                sizes_and_counts = {}
                (0..frozen_table_rows.size - 1).each do |i|
                    size_and_speed = frozen_table_rows[i].xpath("td[contains(@class, 'tire_size_col')]").text().strip()
                    ar = /(\S*) (\S*) (\S*)/.match(size_and_speed)
                    if ar 
                        sizestr = ar[1].gsub(/LT/, '').gsub(/P/, '').gsub(/\/RF/, '').gsub(/ZR/, 'R').gsub(/\/XL/, '').gsub(/C/, '').gsub(/\/E/, '').gsub(/\/D/, '').gsub(/\/LL/, '')
                        sizes_and_counts[sizestr] = 0 if sizes_and_counts[sizestr].nil?
                        sizes_and_counts[sizestr] += 1
                    end
                end

                (0..frozen_table_rows.size - 1).each do |i|
                    size_and_speed = frozen_table_rows[i].xpath("td[contains(@class, 'tire_size_col')]").text().strip()
                    ar = /(\S*) (\S*) (\S*)/.match(size_and_speed)
                    if ar 
                        sizestr = ar[1].gsub(/LT/, '').gsub(/P/, '').gsub(/\/RF/, '').gsub(/ZR/, 'R').gsub(/\/XL/, '').gsub(/C/, '').gsub(/\/E/, '').gsub(/\/D/, '').gsub(/\/LL/, '')
                        load_index = ar[2]
                        speed_rating = ar[3].gsub(/\(/, '').gsub(/\)/, '')

                        product_code = ''
                        begin
                            product_code = frozen_table_rows[i].xpath("td[contains(@class, 'part_number_col')]").text().strip()
                        rescue
                            puts "Could not parse #{frozen_table_rows[i].xpath("td[contains(@class, 'part_number_col')]").text()}"                                
                        end

                        msrp = 0
                        begin
                            msrp = frozen_table_rows[i].xpath("td[contains(@class, 'msrp_col')]").text().strip().to_money.to_s
                        rescue
                            puts "Could not parse #{frozen_table_rows[i].xpath("td[contains(@class, 'msrp_col')]").text()}"
                        end

                        if sizes_and_counts[sizestr] > 1
                            multiples = true
                        else
                            multiples = false
                        end
                        puts "#{product_code} #{sizestr} (MULTI: #{multiples}) #{load_index} #{speed_rating} #{msrp}"

                        tire_size = TireSize.find_by_sizestr(sizestr)

                        if !tire_size
                            invalid_sizes << sizestr if !invalid_sizes.include?(sizestr)
                            ### puts "BAD SIZE #{sizestr}"
                        else
                            #tire_model_info = TireModelInfo.find_by_tire_manufacturer_id_and_tire_model_name(manu.id, model_name)
                            tire_model_info = TireModelInfo.where("tire_manufacturer_id = ? and tire_model_name ilike ?", manu.id, model_name).first
                            if tire_model_info.nil?
                                tire_model_info = TireModelInfo.new
                                tire_model_info.tire_manufacturer_id = manu.id
                                tire_model_info.tire_model_name = model_name
                                tire_model_info.save if create_records

                                puts "*** CREATING TMI RECORD FOR #{model_name}"
                                invalid_tmi << model_name if !invalid_tmi.include?(model_name)
                            end
                            if multiples
                                tire_model = TireModel.find_by_tire_manufacturer_id_and_tire_size_id_and_tire_model_info_id_and_product_code(manu.id, tire_size.id, tire_model_info.id, product_code)
                            else
                                tire_model = TireModel.find_by_tire_manufacturer_id_and_tire_size_id_and_tire_model_info_id(manu.id, tire_size.id, tire_model_info.id)
                            end
                            if tire_model.nil?
                                tire_model = TireModel.new
                                tire_model.tire_manufacturer_id = manu.id
                                tire_model.tire_size_id = tire_size.id
                                tire_model.name = model_name
                                tire_model.tire_model_info_id = tire_model_info.id
                                tire_model.product_code = product_code
                                tire_model.manu_part_num = product_code

                                puts "*** CREATING Tire Model RECORD FOR #{model_name} #{sizestr}"
                            end

                            if !tire_model_info.stock_photo1.exists?
                                img_url = model_data.xpath('//li[@class="ad-thumb"]/a').first
                                if !img_url.nil?
                                    tire_model_info.photo1_url = URI::encode("http://www.michelinman.com" + img_url.attribute('href').text().strip())
                                end
                                puts "**** NO PHOTO: #{tire_model_info.photo1_url}"
                            end

                            tire_model_info.save if create_records

                            sidewall = sliding_table_rows[i].xpath("td[contains(@class, 'sidewall_col')]").text().strip()
                            utqg = sliding_table_rows[i].xpath("td[contains(@class, 'utqg_col')]").text().strip()
                            if utqg != ""
                                ar1 = /(\S*) (\S*) (\S*)/.match(utqg)
                                utqg_treadwear = ar1[1]
                                utqg_traction = ar[2]
                                utqg_temp = ar[3]
                            end
                            orig_tread_depth = sliding_table_rows[i].xpath("td[contains(@class, 'tread_depth_col')]").text().strip()

                            ##puts "#{utqg_treadwear} #{utqg_temp} #{utqg_traction} #{orig_tread_depth}"

                            tire_model.sidewall = sidewall
                            tire_model.utqg_temp = utqg_temp
                            tire_model.utqg_traction = utqg_traction
                            tire_model.utqg_treadwear = utqg_treadwear
                            tire_model.load_index = load_index
                            tire_model.speed_rating = speed_rating
                            tire_model.tread_depth = orig_tread_depth
                            tire_model.orig_cost = msrp
                            tire_model.product_code = product_code
                            tire_model.manu_part_num = product_code

                            tire_model.save if create_records
                        end
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

namespace :ScrapeMichelin do
    desc "Create tire manufacturers data from Michelin"
    task populate: :environment do
        process_michelin_data(true)
    end

    task test: :environment do
        process_michelin_data(false)
    end
end

