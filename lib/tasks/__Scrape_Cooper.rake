require 'nokogiri'
require 'open-uri'
require 'benchmark'

include Benchmark

def ReadData(url)
    RestClient.get url#, :user_agent => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) "
    #open(url, :proxy => "http://54.243.138.45:80", "User-Agent" => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) ").read
end

def rename_existing_model(manu_id, old_name, new_name, create_records)
    models = TireModel.find_all_by_tire_manufacturer_id_and_name(manu_id, old_name)
    puts "Renaming #{models.count} tire models named #{old_name}"
    if create_records
        models.each do |model|
            model.name = new_name
            model.save if create_records
        end
    end

    tmis = TireModelInfo.find_all_by_tire_manufacturer_id_and_tire_model_name(manu_id, old_name) 
    puts "Renaming #{tmis.count} tire model infos named #{old_name}"
    if create_records
        tmis.each do |tmi|
            tmi.tire_model_name = new_name
            tmi.save if create_records
        end
    end
end

def process_cooper_data(create_records)
    manu = TireManufacturer.find_or_create_by_name('Cooper')

    model_xref = {}
    #model_xref(old) = new

    #model_xref["Cinturato P7 All Season"] = 'Cinturato P7'
    #model_xref['P6000 Sport Veloce'] = 'P6000'
    #model_xref['Scorpion Verde All Season'] = 'Scorpion Verde A/S'

    #TireSize.find_or_create_by_sizestr('335/25R22')

    process_coopertire(manu.id, "http://us.coopertire.com/Tires.aspx", create_records, model_xref)
end

def process_coopertire(manu_id, manu_base_url, create_records, model_xref)
    invalid_sizes = []
    invalid_tmi = []
    tot_processed = 0

    old_count = 0
    new_count = 0

    models_found = []
    models_not_found = []
    
    base_response = ""
    (1..5).each do |i|
        begin
            base_response = ReadData(manu_base_url)
            break
        rescue Exception => e 
            puts "Error processing #{manu_base_url}: #{e.to_s} - try again"
        end
    end

    if base_response != '' # there was no error
        base_data = Nokogiri::HTML(base_response.to_s)
        base_data.xpath("//div[@class='category']").each do |category_info|
            if tot_processed > 10
                next
            end

            category_url = category_info.xpath("a").attribute("href").to_s()
            category_name = category_info.xpath("a").attribute("title").to_s()

            category_base_url = "http://us.coopertire.com/#{category_url}"

            category_base_response = ""
            (1..5).each do |i|
                begin
                    category_base_response = ReadData(category_base_url)
                    break
                rescue Exception => e 
                    puts "Error processing #{category_base_url}: #{e.to_s} - try again"
                end
            end

            if category_base_response != ""
                puts "Processing category #{category_name}"

                category_data = Nokogiri::HTML(category_base_response.to_s)
                category_data.xpath("//section[@class='item']").each do |model_info|
                    img_url_temp = model_info.xpath("div[@class='image']/img").attribute("src").to_s()
                    img_url = "http://us.coopertire.com#{img_url_temp}"
                    puts "Img URL: #{img_url}"

                    details_url_temp = model_info.xpath("div[@class='info']/p[@class='get-details']/a").attribute("href").to_s()
                    details_url = "http://us.coopertire.com#{details_url_temp}"
                    puts "Details URL: #{details_url}"

                    model_base_response = ""
                    (1..5).each do |i|
                        begin
                            model_base_response = ReadData(details_url)
                            break
                        rescue Exception => e 
                            puts "Error processing #{details_url}: #{e.to_s} - try again"
                        end
                    end

                    if model_base_response != ""
                        model_data = Nokogiri::HTML(model_base_response.to_s)
                        model_name_temp = model_data.xpath("//h1").text().to_s

                        encoding_options = {
                            :invalid           => :replace,  # Replace invalid byte sequences
                            :undef             => :replace,  # Replace anything not defined in ASCII
                            :replace           => '',        # Use a blank for those replacements
                            :universal_newline => true       # Always break lines with \n
                        }                        

                        model_name = model_name_temp.gsub(/\s+/, " ").strip.encode(Encoding.find('ASCII'), encoding_options).gsub(/Cooper /, '')

                        ar_warranty_miles = /(\d{2,3},\d{2,3}) Mile Treadwear Protection/.match(model_data)
                        if ar_warranty_miles
                            warranty_miles = ar_warranty_miles[1].gsub(/,/, '')
                        else
                            warranty_miles = ""
                        end

                        puts "Model: #{model_name}"
                        puts "Warranty: #{warranty_miles}"

                        tmi = TireModelInfo.where("tire_manufacturer_id = ? and tire_model_name ilike ?", manu_id, model_name).first

                        if tmi.nil?
                            models_not_found << model_name

                            tmi = TireModelInfo.new 
                            tmi.tire_manufacturer_id = manu_id 
                            tmi.tire_model_name = model_name 
                            if create_records
                                tmi.save
                            end
                        else
                            models_found << model_name
                        end

                        tmi.photo1_url = img_url
                        if create_records
                            tmi.save
                        end
                        
                        model_data.xpath("//div[@id='tire-specs']/div[@class='table']/table/tr").each do |size_info|
                            ar_size_info = size_info.xpath("td")

                            if ar_size_info.length > 10
                                sizestr_temp = ar_size_info[0].text()

                                ar_size_temp = /(LT|)(\d{3})(\/)(\d{2})(R)(\d{2})/.match(sizestr_temp)

                                if ar_size_temp.nil? || ar_size_temp.length < 6
                                    puts "**** FAIL **** (#{sizestr_temp})"
                                    sizestr = "*** FAIL ***"
                                    tire_code = "*** FAIL ***"
                                else
                                    tire_code = ar_size_temp[1]
                                    sizestr = ar_size_temp[2..99].join("")

                                    ts = TireSize.find_by_sizestr(sizestr)

                                    if ts.nil?
                                        puts "*** COULD NOT FIND #{sizestr} ***"
                                    end

                                    svc = ar_size_info[1]
                                    ar_svc = /(\d{2,3})(\w)/.match(svc)
                                    if ar_svc && ar_svc.length >= 2
                                        load_index = ar_svc[1]
                                        speed_rating = ar_svc[2]
                                    else
                                        load_index = ""
                                        speed_rating = ""
                                    end

                                    utqg = ar_size_info[2]
                                    ar_utqg = /(\d{2,3}) (\w{1,2}) (\w{1})/.match(utqg)
                                    if ar_utqg && ar_utqg.length >= 2
                                        utqg_treadwear = ar_utqg[1]
                                        utqg_traction = ar_utqg[2]
                                        utqg_temp = ar_utqg[3]
                                    else
                                        utqg_treadwear = ""
                                        utqg_traction = ""
                                        utqg_temp = ""
                                    end

                                    sidewall = ar_size_info[4].text()

                                    tread_depth = ar_size_info[11].text()

                                    tm = TireModel.find_by_tire_manufacturer_id_and_tire_size_id_and_tire_model_info_id_and_tire_code(manu_id, ts.id, tmi.id, tire_code)

                                    if !tm.nil?
                                        old_count += 1
                                    else
                                        new_count += 1
                                        tm = TireModel.new
                                    end

                                    tm.tire_manufacturer_id = manu_id
                                    tm.tire_size_id = ts.id
                                    tm.tire_model_info_id = tmi.id 
                                    tm.tire_code = tire_code
                                    tm.load_index = load_index
                                    tm.speed_rating = speed_rating
                                    tm.utqg_treadwear = utqg_treadwear
                                    tm.utqg_traction = utqg_traction
                                    tm.utqg_temp = utqg_temp
                                    tm.sidewall = sidewall
                                    tm.tread_depth = tread_depth

                                    puts "Size: #{sizestr}"
                                    puts "Load: #{load_index}"
                                    puts "Speed: #{speed_rating}"
                                    puts "UTQG Treadwear: #{utqg_treadwear}"
                                    puts "UTQG Traction: #{utqg_traction}"
                                    puts "UTQG Temp: #{utqg_temp}"
                                    puts "Sidewall: #{sidewall}"
                                    puts "Tread: #{tread_depth}"

                                    if create_records
                                        tm.save
                                    end
                                end
                            end
                        end

                        puts "------------------------------------"
                        puts ""
                    end
                end
            end

            if false
            model_url = model_info.xpath("a").attribute("href").to_s()
            model_name = model_info.xpath("a/div[@class='tileHead']").text.to_s()

            if !model_xref[model_name].nil?
                model_name = model_xref[model_name]
            end

            #puts "Product: #{model_name} #{model_url}"
            tire_model_info = TireModelInfo.where("tire_manufacturer_id = ? and tire_model_name ilike ?", manu_id, model_name).first
            if tire_model_info.nil?
                tire_model_info = TireModelInfo.new
                tire_model_info.tire_manufacturer_id = manu_id
                tire_model_info.tire_model_name = model_name
                tire_model_info.save if create_records

                #puts "*** CREATING TMI RECORD FOR #{model_name}"
                invalid_tmi << model_name if !invalid_tmi.include?(model_name)
            end
            if !tire_model_info.stock_photo1.exists?
                img_url = model_info.xpath('a/div/img/@src').text().strip()
                if !img_url.nil?
                    tire_model_info.photo1_url = img_url
                end
                #puts "**** NO PHOTO: #{tire_model_info.photo1_url}"
            end

            tire_model_info.save if create_records

            product_info_response = ''
            (1..5).each do |i|
                begin
                    #puts "http://www.continentaltire.com#{category_url}"
                    product_info_response = ReadData("http://www.simpletire.com#{model_url}")
                    break
                rescue Exception => e
                    puts "Error processing #{category_url}: #{e.to_s} - try again"
                end
            end

            if product_info_response != ""
                model_data = Nokogiri::HTML(product_info_response.to_s)

                # 07/02/13 ksi
                # we need to see if there are multiple sizes for the same model/manufacturer.
                # if so, we need multiple records.
                sizes_and_counts = {}
                model_data.xpath("//ul[@class='prodRow']").each do |size_row|
                    product_code = size_row.xpath("li[@class='i1']/a/span[@itemprop='productID']").text.to_s.strip
                    sizestr = size_row.xpath("li[@class='i2']").text.to_s.strip

                    arSize = /(|P|LT)(\d{3})(\ x|x|\/)(\d{2})(R|ZR)(\d{2})/.match(sizestr)

                    if arSize
                        sizestr = "#{arSize[2]}/#{arSize[4]}R#{arSize[6]}"
                        sizes_and_counts[sizestr] = 0 if sizes_and_counts[sizestr].nil?
                        sizes_and_counts[sizestr] += 1
                    end
                end

                model_data.xpath("//ul[@class='prodRow']").each do |size_row|
                    product_code = size_row.xpath("li[@class='i1']/a/span[@itemprop='productID']").text.to_s.strip
                    sizestr = size_row.xpath("li[@class='i2']").text.to_s.strip
                    load_speed = size_row.xpath("li[@class='i3']").text.to_s.strip

                    ar3 = load_speed.scan(/(\d{2,})(\D).*/)[0]
                    if ar3
                        load_index = ar3[0]
                        speed_rating = ar3[1]
                    end

                    item_no = size_row.xpath("li[@class='i6']/a/@id").text.to_s.strip.gsub(/expand-/, '')

                    arSize = /(|P|LT)(\d{3})(\ x|x|\/)(\d{2})(R|ZR)(\d{2})/.match(sizestr)
                    if !arSize
                        puts "**** COULD NOT PARSE SIZE #{sizestr}"
                        invalid_sizes << sizestr if !invalid_sizes.include?(sizestr)
                    else
                        # now get the parts
                        tire_code = arSize[1]
                        tire_code = "P" if tire_code == ""
                        sizestr = "#{arSize[2]}/#{arSize[4]}R#{arSize[6]}"

                        if sizes_and_counts[sizestr] > 1
                            multiples = true
                        else
                            multiples = false
                        end
                        puts "**** #{sizestr} MULTIPLE:#{multiples}"
                        ts = TireSize.find_by_sizestr(sizestr)
                        if ts.nil?
                            invalid_sizes << sizestr if !invalid_sizes.include?(sizestr)
                        else
                            product_details_response = ''
                            (1..5).each do |i|
                                begin
                                    product_details_response = ReadData("http://simpletire.com/catalog_browse/item_detail/#{item_no}")
                                    break
                                rescue Exception => e
                                    puts "Error processing product details: #{e.to_s} - try again"
                                end
                            end

                            if product_details_response != ""
                                tot_processed += 1

                                product_details_data = Nokogiri::HTML(product_details_response.to_s)

                                warranty_miles = product_details_data.xpath("//span[@class='warranty']").text.to_s.strip
                                warranty_miles = "" if warranty_miles == "N/A"

                                sidewall = product_details_data.xpath("//span[@class='side-wall']").text.to_s.strip
                                utqg = product_details_data.xpath("//span[@class='utqg']").text.to_s.strip

                                if utqg != ""
                                    ar1 = utqg.scan(/(\d*) *(\D*)/)[0]
                                    if ar1
                                        utqg_treadwear = ar1[0]
                                        traction_temp = ar1[1].strip()

                                        if traction_temp.length > 1
                                            utqg_traction = traction_temp[0..traction_temp.length - 2]
                                            utqg_temp = traction_temp[-1..-1]
                                        else
                                            utqg_traction = ""
                                            utqg_temp = ""
                                        end
                                    end
                                end

                                puts "MODEL: #{model_name}"
                                puts "PRODUCT CODE: #{product_code}"
                                puts "SIZE: #{sizestr}"
                                #puts "LOADSPEED: #{load_speed}"
                                puts "LOAD: #{load_index}"
                                puts "SPEED: #{speed_rating}"
                                puts "WARRANTY: #{warranty_miles}"
                                puts "SIDEWALL: #{sidewall}"
                                puts "UTQG: (#{utqg}) #{utqg_treadwear}/#{utqg_temp}/#{utqg_traction}"
                                puts " "

                                if multiples
                                    tire_model = TireModel.find_by_tire_manufacturer_id_and_tire_size_id_and_tire_model_info_id_and_product_code(manu_id, ts.id, tire_model_info.id, product_code)
                                else
                                    tire_model = TireModel.find_by_tire_manufacturer_id_and_tire_size_id_and_tire_model_info_id_and_tire_code(manu_id, ts.id, tire_model_info.id, tire_code)
                                    tire_model = TireModel.find_by_tire_manufacturer_id_and_tire_size_id_and_tire_model_info_id_and_tire_code(manu_id, ts.id, tire_model_info.id, "") if tire_model.nil?
                                    tire_model = TireModel.find_by_tire_manufacturer_id_and_tire_size_id_and_tire_model_info_id_and_tire_code(manu_id, ts.id, tire_model_info.id, nil) if tire_model.nil?
                                end

                                if tire_model.nil?
                                    tire_model = TireModel.new
                                    tire_model.tire_manufacturer_id = manu_id
                                    tire_model.tire_size_id = ts.id
                                    tire_model.name = model_name
                                    tire_model.tire_model_info_id = tire_model_info.id
                                    tire_model.tire_code = tire_code

                                    #puts "*** CREATING Tire Model RECORD FOR #{model_name} #{sizestr}"
                                else
                                    #puts "*** ALREADY HAVE Tire Model RECORD FOR #{model_name} #{sizestr}"
                                end

                                tire_model.sidewall = sidewall
                                tire_model.utqg_temp = utqg_temp
                                tire_model.utqg_traction = utqg_traction
                                tire_model.utqg_treadwear = utqg_treadwear
                                tire_model.load_index = load_index
                                tire_model.speed_rating = speed_rating
                                #tire_model.tread_depth = orig_tread_depth
                                #tire_model.orig_cost = msrp
                                tire_model.product_code = product_code
                                tire_model.manu_part_num = product_code

                                tire_model.save if create_records
                            end
                        end
                    end
                end                
            end
            end
        end
    end

    puts "**** EXCEPTION REPORT ****"
    puts "Total processed: #{tot_processed}"
    puts "Invalid sizes: "
    puts "\t" + invalid_sizes.join("\n\t")
    puts ""
    puts "Invalid TMI: "
    puts "\t" + invalid_tmi.join("\n\t")
    puts ""
    puts "Models found: "
    puts "\t" + models_found.join("\n\t")
    puts ""
    puts "Models not found: "
    puts "\t" + models_not_found.join("\n\t")
    puts ""
    puts "OLD: #{old_count}"
    puts "NEW: #{new_count}"
end

namespace :ScrapeCooper do
    desc "Create tire manufacturers data from Cooper"
    task populate: :environment do
        puts Benchmark.measure {
            process_cooper_data(true)
        }
    end

    task test: :environment do
        puts Benchmark.measure {
            process_cooper_data(false)
        }
    end
end
