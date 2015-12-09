require 'nokogiri'
require 'open-uri'

def ReadData(url)
    RestClient.get url#, :user_agent => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) "
    #open(url, :proxy => "http://54.243.138.45:80", "User-Agent" => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) ").read
end

def fix_model_name(model_name)
    case model_name.upcase
    when 'ECSTA MX XRP'
        'Ecsta MX KU15'
    when 'ROAD VENTURE SAT'
        'Road Venture SAT KL61'
    else
        model_name
    end
end

def get_warranty_for_model(tire_model)
    #puts "NEED WARRANTY FOR #{tire_model}"

    case tire_model.upcase
    when "ECSTA 4X KU22"
        40000
    when "ECOWING KH30"
        60000
    when "ECSTA LX PLATINUM KU27"
        60000
    when "ECSTA ASX KU21", "ECSTA AST KU25"
        30000
    when "SOLUS KH16"
        60000
    when "SOLUS KR21"
        85000
    when "SENSE KR26"
        40000
    when "solus kl21"
        60000
    when "road venture apt"
        60000
    when "road venture sat"
        60000
    when "SOLUS XPERT KH20"
        50000
    when "ECSTA MX KU15", "ECSTA SPT KU31", "ECSTA LE SPORT KU39", "ECSTA XS", "SOLUS KH25"
        0
    else
        puts "*** NEED WARRANTY FOR #{tire_model}"
    end
end

namespace :ScrapeKumho do
    desc "Create tire manufacturers data from Kumho"
    task populate: :environment do
        base_url = "http://www.kumhousa.com"
        manu = TireManufacturer.find_or_create_by_name('Kumho')

        arFound = []
        arNotFound = []
        arSizes = []

        # process categories
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
            category_name = ""
            base_data.xpath("//div[@class='drop-two']/ul/li").each do |cats_and_models|
                #puts cats_and_models
                if cats_and_models.children().search("div[@class='tire-cat-sub']").size == 1
                    category_name = cats_and_models.children().search("div[@class='tire-cat-sub']").text().strip()
                else
                    # I'm not processing these truck tires just yet
                    if category_name != "Rib (Steer/All Positions/Trailer)" &&
                        category_name != "Drive (Traction)" &&
                        category_name != "17.5/19.5 Rim Sizes" &&
                        category_name != "On/Off Highway" 

                        puts "****************** #{category_name}"
                        model_link = cats_and_models.children.search("a").first

                        model_url = "http://www.kumhousa.com#{model_link.attribute('href')}"
                        model_name = fix_model_name(model_link.text().strip())

                        # these models have sizes I'm not yet ready for
                        if model_name != "RADIAL 798" && model_name != "RADIAL 857"
                            puts "#{model_name} #{model_url}"

                            model_response = ''
                            (1..5).each do |i|
                                begin
                                    model_response = ReadData(model_url)
                                    break
                                rescue Exception => e 
                                    puts "Error processing #{model_url}: #{e.to_s} - try again"
                                end
                            end

                            if model_response != ''
                                model_data = Nokogiri::HTML(model_response.to_s)

                                # tread code
                                tread_code = ''
                                tread_code_text = model_data.xpath("//h3[contains(., 'TREAD CODE')]")
                                if tread_code_text
                                    ar = /TREAD CODE: (.*)/.match(tread_code_text.text().strip())
                                    tread_code = ar[1].gsub(/ /, '').gsub(/\-/, '') if ar 
                                end

                                model_str = "#{model_name}"
                                first_tm = TireModel.find(:first, :conditions => ['UPPER(name) = UPPER(?)', model_str])
                                if !first_tm && !model_name.include?(tread_code)
                                    model_str = "#{model_name} #{tread_code}"
                                    first_tm = TireModel.find(:first, :conditions => ['UPPER(name) = UPPER(?)', model_str])
                                end

                                if first_tm
                                    model_str = first_tm.name
                                end

                                tc = TireCategory.find_or_create_by_category_name(category_name)

                                # let's go ahead and create or update the TireModelInfo 
                                # record as well
                                description = model_data.xpath("(//div[@id='content']/p)[1]").text()
                                img_url = model_data.xpath("//div[@class='tire-image']/img").attribute("src")
                                tmi = TireModelInfo.find_or_create_by_tire_manufacturer_id_and_tire_model_name(manu.id, model_str)
                                if !tmi.photo1_url
                                    tmi.photo1_url = img_url.text()
                                end
                                tmi.description = description
                                #puts "TMI: #{tmi.photo1_url} #{tmi.description}"
                                tmi.save

                                # get model stuff
                                sizes_url = model_url.gsub(/\/category\/car\//, '/sizeframe/')
                                
                                # process sizes
                                sizes_response = ''
                                (1..5).each do |i|
                                    begin
                                        sizes_response = ReadData(sizes_url)
                                        break
                                    rescue Exception => e 
                                        puts "Error processing #{sizes_url}: #{e.to_s} - try again"
                                    end
                                end

                                if sizes_response != ""
                                    # figure out which columns hold which information
                                    sizes_data = Nokogiri::HTML(sizes_response.to_s)
                                    header_tr = sizes_data.xpath("(//table[@class='table-sizes']//tr)[1]")
                                    
                                    tire_size_col = product_code_col = service_desc_col = construction_col = -1
                                    sidewall_col = utqg_col = rim_width_col = section_width_col = overall_diam_col = -1
                                    tire_weight_col = static_load_radius_col = rpm_col = tread_depth_col = -1
                                    max_load_single_col = max_load_dual_col = max_inflation_col = -1

                                    if header_tr
                                        # process columns to see which data is in which column
                                        #puts "checking columns"
                                        i = 0
                                        header_tr.xpath("th").each do |col|
                                            txt = col.text().strip().downcase
                                            if txt.include?("tire size")
                                                tire_size_col = i
                                            elsif txt.include?("product code")
                                                product_code_col = i 
                                            elsif txt.include?("service desc")
                                                service_desc_col = i 
                                            elsif txt.include?("construction")
                                                construction_col = i
                                            elsif txt.include?("sidewall")
                                                sidewall_col = i 
                                            elsif txt.include?("utqg")
                                                utqg_col = i 
                                            elsif txt.include?("rim width")
                                                rim_width_col = i 
                                            elsif txt.include?("section width")
                                                section_width_col = i 
                                            elsif txt.include?("overall dia")
                                                overall_diam_col = i
                                            elsif txt.include?("tire weight")
                                                tire_weight_col = i 
                                            elsif txt.include?("static load")
                                                static_load_radius_col = i 
                                            elsif txt.include?("rpm")
                                                rpm_col = i 
                                            elsif txt.include?("tread depth")
                                                tread_depth_col = i 
                                            elsif txt.include?("max load single")
                                                max_load_single_col = i 
                                            elsif txt.include?("max load dual")
                                                max_load_dual_col = i 
                                            elsif txt.include?("max inflation")
                                                max_inflation_col = i 
                                            else
                                                puts "*** DID NOT RECOGNIZE COLUMN WITH HEADER #{txt}"
                                            end
                                            i += 1
                                        end
                                    end

                                    # now process each non-header row
                                    i = 0
                                    sizes_data.xpath("//table[@class='table-sizes']//tr").each do |size_row|
                                        if i > 0
                                            data_cols = size_row.xpath("td")
                                            tire_size = data_cols[tire_size_col].text().strip()
                                            product_code = data_cols[product_code_col].text().strip()
                                            service_desc = data_cols[service_desc_col].text().strip()
                                            construction = data_cols[construction_col].text().strip()
                                            sidewall = data_cols[sidewall_col].text().strip()
                                            utqg = data_cols[utqg_col].text().strip()
                                            rim_width = data_cols[rim_width_col].text().strip()
                                            section_width = data_cols[section_width_col].text().strip()
                                            overall_diam = data_cols[overall_diam_col].text().strip()
                                            tire_weight = data_cols[tire_weight_col].text().strip()
                                            static_load_radius = data_cols[static_load_radius_col].text().strip()
                                            rpm = data_cols[rpm_col].text().strip()
                                            tread_depth = data_cols[tread_depth_col].text().strip()
                                            max_load_single = data_cols[max_load_single_col].text().strip()
                                            max_load_dual = data_cols[max_load_dual_col].text().strip()
                                            max_inflation = data_cols[max_inflation_col].text().strip()

                                            # standardize the tiresize information
                                            if !arSizes.include?(utqg.upcase)
                                                arSizes << utqg.upcase
                                            end

                                            ar = /(|P|LT)(\d{3})(x|\/)(\d{2})(ZR|R)(\d{2})/.match(tire_size)
                                            if !ar
                                                puts "OOPS - could not parse #{tire_size}"
                                                next
                                            end
                                            tire_code = ar[1]
                                            tire_code = "P" if tire_code == ""
                                            sizestr = "#{ar[2]}/#{ar[4]}R#{ar[6]}"

                                            ts = TireSize.find_by_sizestr(sizestr)

                                            ar = /(\d{2,3})(\D)/.match(service_desc)
                                            if ar
                                                load_index = ar[1]
                                                speed_rating = ar[2]
                                            end

                                            ar = /(\d{3})( |\/)*(A{1,2})( |\/)*(\D{1})/.match(utqg)
                                            if ar 
                                                utqg_treadwear = ar[1]
                                                utqg_traction = ar[3]
                                                utqg_temperature = ar[5]
                                            end

                                            # we should have enough information to create or update
                                            # a TireModel record
                                            tm = TireModel.find_or_create_by_tire_manufacturer_id_and_tire_size_id_and_name(manu.id, ts.id, model_str)
                                            tm.sidewall = sidewall
                                            tm.utqg_temp = utqg_temperature
                                            tm.utqg_traction = utqg_traction
                                            tm.utqg_treadwear = utqg_treadwear
                                            tm.load_index = load_index
                                            tm.rim_width = rim_width
                                            tm.speed_rating = speed_rating
                                            tm.tread_depth = tread_depth
                                            tm.product_code = product_code
                                            tm.construction = construction
                                            tm.weight = tire_weight
                                            tm.warranty_miles = get_warranty_for_model(model_str)
                                            tm.tire_code = tire_code

                                            tm.save
                                        end
                                        i += 1
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

