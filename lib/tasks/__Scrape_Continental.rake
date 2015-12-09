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

def process_pirelli_data(create_records)
    manu = TireManufacturer.find_or_create_by_name('Pirelli')

    model_xref = {}
    #model_xref(old) = new
    model_xref["Cinturato P7 All Season"] = 'Cinturato P7'
    model_xref['P6000 Sport Veloce'] = 'P6000'
    model_xref['Scorpion Verde All Season'] = 'Scorpion Verde A/S'

    TireSize.find_or_create_by_sizestr('335/25R22')
    TireSize.find_or_create_by_sizestr('355/30R19')
    TireSize.find_or_create_by_sizestr('305/30R22')
    TireSize.find_or_create_by_sizestr('375/20R21')
    TireSize.find_or_create_by_sizestr('265/25R23')
    TireSize.find_or_create_by_sizestr('275/25R26')
    TireSize.find_or_create_by_sizestr('405/25R24')
    TireSize.find_or_create_by_sizestr('355/25R19')
    TireSize.find_or_create_by_sizestr('285/45R18')
    TireSize.find_or_create_by_sizestr('295/25R26')
    TireSize.find_or_create_by_sizestr('315/40R25')
    TireSize.find_or_create_by_sizestr('315/30R30')

    process_simpletire(manu.id, "http://simpletire.com/pirelli-tires", create_records, model_xref)
end

def process_maxxis_data(create_records)
    manu = TireManufacturer.find_or_create_by_name('Maxxis')

    model_xref = {}
    #model_xref(old) = new
    #model_xref["Cinturato P7 All Season"] = 'Cinturato P7'
    #model_xref['P6000 Sport Veloce'] = 'P6000'
    #model_xref['Scorpion Verde All Season'] = 'Scorpion Verde A/S'

    process_simpletire(manu.id, "http://simpletire.com/maxxis-tires", create_records, model_xref)
end

def process_uniroyal_data(create_records)
    manu = TireManufacturer.find_or_create_by_name('Uniroyal')

    model_xref = {}
    #model_xref(old) = new
    #model_xref["Cinturato P7 All Season"] = 'Cinturato P7'
    #model_xref['P6000 Sport Veloce'] = 'P6000'
    #model_xref['Scorpion Verde All Season'] = 'Scorpion Verde A/S'

    #TireSize.find_or_create_by_sizestr('335/25R22')
    rename_existing_model(manu.id, "Tiger Paw AS-6000", "Tiger Paw AS6000", create_records)
    rename_existing_model(manu.id, "Tiger Paw Touring (TT)", "Tiger Paw Touring TT", create_records)
    rename_existing_model(manu.id, "Tiger Paw Ice & Snow II", "Tiger Paw Ice & Snow", create_records)
    rename_existing_model(manu.id, "Tiger Paw AWP II", "Tiger Paw AWP", create_records)

    process_simpletire(manu.id, "http://simpletire.com/uniroyal-tires", create_records, model_xref)
end

def process_bfgoodrich_data(create_records)
    manu = TireManufacturer.find_or_create_by_name('BFGoodrich')

    model_xref = {}
    #model_xref(old) = new
    model_xref["g-Force Super Sport A/S H/V"] = "g-Force Super Sport A/S"
    model_xref['Mud Terrain T/A KM'] = "Mud-Terrain T/A KM"
    #model_xref['Scorpion Verde All Season'] = 'Scorpion Verde A/S'

    #TireSize.find_or_create_by_sizestr('335/25R22')
    rename_existing_model(manu.id, "Commercial T/A All-Season", "Commercial T/A All Season", create_records)
    rename_existing_model(manu.id, "g-Force T/A Drag Radial (TT)", "g-Force T/A Drag Radial", create_records)
    rename_existing_model(manu.id, "g-Force T/A KDW (TT)", "g-Force T/A KDW", create_records)
    rename_existing_model(manu.id, "Winter Slalom KSI", "Winter Slalom", create_records)

    process_simpletire(manu.id, "http://simpletire.com/bfgoodrich-tires", create_records, model_xref)
end

def process_continental_data(create_records)
    manu = TireManufacturer.find_or_create_by_name('Continental')

    model_xref = {}
    #model_xref(old) = new
    model_xref['4X4 Winter Contact'] = '4X4 WinterContact'
    model_xref['Vanco 4 Season'] = 'Vanco4Season'
    model_xref['ContiTouringContact CH 95'] = 'ContiTouringContact CH95'
    model_xref['ContiTouringContact CT 95'] = 'ContiTouringContact CT95'
    model_xref['ContiTouringContact CV 95'] = 'ContiTouringContact CV95'
    model_xref['ContiTouringContact CW 95'] = 'ContiTouringContact CW95'
    model_xref['Conti Winter Contact TS830P'] = 'ContiWinterContact TS830P'
    model_xref['CrossContact UHP'] = 'ContiCrossContact UHP'
    model_xref['ProContact EcoPlus'] = 'ProContact with EcoPlus Technology'
    model_xref['ContiPremierContact'] = 'ContiPremiumContact'
    model_xref['ContiSportContact 5P'] = 'ContiSportContact 5 P'
    model_xref['CrossContact LX20'] = 'CrossContact LX20 w/ Eco Plus'

    process_simpletire(manu.id, "http://simpletire.com/continental-tires", create_records, model_xref)
end

def backfill_michelin_data(create_records)
    manu = TireManufacturer.find_or_create_by_name('Michelin')

    model_xref = {}
    #model_xref(old) = new
    #model_xref['4X4 Winter Contact'] = '4X4 WinterContact'

    backfill_simpletire(manu.id, "http://simpletire.com/michelin-tires", create_records, model_xref)
end

def process_simpletire(manu_id, manu_base_url, create_records, model_xref)
    invalid_sizes = []
    invalid_tmi = []
    tot_processed = 0
    
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
        base_data.xpath("//div[@class='prodTile']/div").each do |model_info|
            if tot_processed > 5000000
                next
            end

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

    puts "**** EXCEPTION REPORT ****"
    puts "Total processed: #{tot_processed}"
    puts "Invalid sizes: "
    puts "\t" + invalid_sizes.join("\n\t")
    puts ""
    puts "Invalid TMI: "
    puts "\t" + invalid_tmi.join("\n\t")    
end

def backfill_summitracing(manu_id, manu_part_num_code, manu_short_name, manu_base_url, create_records, model_xref)
    invalid_sizes = []
    invalid_tmi = []
    tot_processed = 0

    tot_already_found = 0
    tot_not_already_found = 0
    tot_bad_tmi = 0
    
    base_response = ""
    (1..99).each do |page_num|
        manu_page_url = ""
        (1..5).each do |i|
            begin
                manu_page_url = "#{manu_base_url}?page=#{page_num}"
                base_response = ReadData(manu_page_url)
                break
            rescue Exception => e 
                puts "Error processing #{manu_page_url}: #{e.to_s} - try again"
            end
        end

        puts "Processing page #{page_num}"
        if base_response != '' # there was no error
            base_data = Nokogiri::HTML(base_response.to_s)
            if base_data.xpath("//div[@class='attention']").count > 0
                puts "**** Could not read page #{page_num}"
                break
            else
                base_data.xpath("//div[@class='item']").each do |model_info|
                    model_num = model_info.xpath('./div[@class="column"]/p[@class="results-part-number"]/strong/following-sibling::text()').text.strip.to_s.gsub(/#{manu_part_num_code}-/, '')
                    model_details_url = model_info.xpath('./h2[@class="title"]/a/@href').text.strip.to_s

                    tm = TireModel.find_by_tire_manufacturer_id_and_product_code(manu_id, model_num)
                    if tm.nil?
                        model_response = ""
                        (1..5).each do |i|
                            begin
                                model_page_url = URI::join(manu_page_url, model_details_url).to_s
                                model_response = ReadData(model_page_url)
                                break
                            rescue Exception => e 
                                puts "Error processing #{model_page_url}: #{e.to_s} - try again"
                            end
                        end
                        if model_response != ""
                            model_data = Nokogiri::HTML(model_response.to_s)
                            rawsize = model_data.xpath("//span[contains(., 'Tire Size')]/following-sibling::span/text()").text.strip.to_s
                            sizestr = rawsize.gsub(/-/, 'R')
                            ts = TireSize.find_by_sizestr(sizestr)
                            if ts.nil?
                                invalid_sizes << rawsize
                            else
                                tot_not_already_found += 1
                                speed_rating = model_data.xpath("//span[contains(., 'Speed Rating')]/following-sibling::span/text()").text.strip.to_s
                                load_index = model_data.xpath("//span[contains(., 'Load Range')]/following-sibling::span/text()").text.strip.to_s
                                utqg_treadwear = model_data.xpath("//span[contains(., 'UTQG Tread Wear Rating')]/following-sibling::span/text()").text.strip.to_s
                                utqg_traction = model_data.xpath("//span[contains(., 'Traction Rating')]/following-sibling::span/text()").text.strip.to_s
                                utqg_temp = model_data.xpath("//span[contains(., 'Temperature Rating')]/following-sibling::span/text()").text.strip.to_s
                                tread_depth = model_data.xpath("//span[contains(., 'Tread Depth')]/following-sibling::span/text()").text.strip.to_s.gsub('/\/32 in.', '')
                                model_name = model_data.xpath("//h1[@class='title']").text.to_s.scan(/#{manu_short_name} (.*) Tires #{model_num}/)[0][0]
                                if !model_xref[model_name].nil?
                                    model_name = model_xref[model_name]
                                end

                                tmi = TireModelInfo.find_by_tire_manufacturer_id_and_tire_model_name(manu_id, model_name)
                                if tmi.nil?
                                    puts "#{model_name} - ---->not found"
                                else
                                    # now create a new tire model record
                                    tm = TireModel.new
                                    tm.name = model_name
                                    tm.product_code = model_num
                                    tm.tire_manufacturer_id = manu_id
                                    tm.tire_model_info_id = tmi.id 
                                    tm.tire_size_id = ts.id 
                                    tm.speed_rating = speed_rating
                                    tm.load_index = load_index
                                    tm.utqg_temp = utqg_temp
                                    tm.utqg_treadwear = utqg_treadwear
                                    tm.utqg_traction = utqg_traction
                                    tm.tread_depth = tread_depth
                                    tm.save if create_records
                                end
                            end
                        end
                    else
                        tot_already_found += 1
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
    puts "already found: #{tot_already_found} not found: #{tot_not_already_found}"  

    puts model_xref
end

def backfill_bfg_data(create_records)
    manu = TireManufacturer.find_or_create_by_name('BF Goodrich')

    model_xref = {}
    #model_xref(old) = new
    model_xref["g-Force R-1"] = "g-Force R1"

    backfill_summitracing(manu.id, "BFG", "BFGoodrich", "http://www.summitracing.com/search/department/wheels-tires/part-type/tires/brand/bfgoodrich-tires", create_records, model_xref)
end

def backfill_simpletire(manu_id, manu_base_url, create_records, model_xref)
    invalid_sizes = []
    invalid_tmi = []
    tot_processed = 0

    tot_already_found = 0
    tot_not_already_found = 0
    tot_bad_tmi = 0
    
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
        base_data.xpath("//div[@class='prodTile']/div").each do |model_info|
            model_url = model_info.xpath("a").attribute("href").to_s()
            model_name = model_info.xpath("a/div[@class='tileHead']").text.to_s()

            if !model_xref[model_name].nil?
                model_name = model_xref[model_name]
            end

            if false
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
            end

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

                                tire_model = TireModel.find_by_tire_manufacturer_id_and_product_code(manu_id, product_code)

                                if tire_model.nil?
                                    # check for tire model info
                                    tire_model_info = TireModelInfo.where("tire_manufacturer_id = ? and tire_model_name ilike ?", manu_id, model_name).first
                                    if tire_model_info.nil?
                                        tot_bad_tmi += 1
                                        puts "*** INVALID TMI FOR #{model_name}"
                                    else
                                        tot_not_already_found += 1
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

                                        tire_model = TireModel.new
                                        tire_model.tire_manufacturer_id = manu_id
                                        tire_model.tire_size_id = ts.id
                                        tire_model.name = model_name
                                        tire_model.tire_model_info_id = tire_model_info.id
                                        tire_model.tire_code = tire_code

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
                                else
                                    tot_already_found += 1
                                end
                            end
                        end
                    end
                end                
            end
        end
    end
    puts "Total already found: #{tot_already_found}"
    puts "Total new: #{tot_not_already_found}"
    puts "Bad TMI: #{tot_bad_tmi}"
end

namespace :ScrapeContinental do
    desc "Create tire manufacturers data from Continental"
    task populate: :environment do
        puts Benchmark.measure {
            process_continental_data(true)
        }
    end

    task test: :environment do
        puts Benchmark.measure {
            process_continental_data(false)
        }
    end
end

namespace :ScrapeUniroyal do
    desc "Create tire manufacturers data from Uniroyal"
    task populate: :environment do
        puts Benchmark.measure {
            process_uniroyal_data(true)
        }
    end

    task test: :environment do
        puts Benchmark.measure {
            process_uniroyal_data(false)
        }
    end
end

namespace :ScrapePirelli do
    desc "Create tire manufacturers data from Pirelli"
    task populate: :environment do
        puts Benchmark.measure {
            process_pirelli_data(true)
        }
    end

    task test: :environment do
        puts Benchmark.measure {
            process_pirelli_data(false)
        }
    end
end

namespace :ScrapeBFGoodrich do
    desc "Create tire manufacturers data from BF Goodrich"
    task populate: :environment do
        puts Benchmark.measure {
            process_bfgoodrich_data(true)
        }
    end

    task test: :environment do
        puts Benchmark.measure {
            process_bfgoodrich_data(false)
        }
    end
end

namespace :ScrapeMaxxis do
    desc "Create tire manufacturers data from Maxxis"
    task populate: :environment do
        puts Benchmark.measure {
            process_maxxis_data(true)
        }
    end

    task test: :environment do
        puts Benchmark.measure {
            process_maxxis_data(false)
        }
    end
end

namespace :BackfillMichelin do
    desc "Create tire manufacturers data from Michelin from simple tire"
    task populate: :environment do
        puts Benchmark.measure {
            backfill_michelin_data(true)
        }
    end

    task test: :environment do
        puts Benchmark.measure {
            backfill_michelin_data(false)
        }
    end
end


namespace :BackfillBFG do
    desc "Create tire manufacturers data from BGF from summit racing"
    task populate: :environment do
        puts Benchmark.measure {
            backfill_bfg_data(true)
        }
    end

    task test: :environment do
        puts Benchmark.measure {
            backfill_bfg_data(false)
        }
    end
end
