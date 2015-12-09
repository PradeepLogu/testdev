#require 'nokogiri'
#require 'open-uri'

namespace :ImportTGPData do
    desc "Update tire model and tire model info table with data from TGP"

    task delete_old_tire_model_infos: :environment do
        TireModelInfo.all.each do |tmi|
            if tmi.tire_models.size == 0
                puts "Deleted #{tmi.tire_model_name} #{tmi.updated_at}"
                tmi.destroy
            end
        end
    end

    task update_tgp_model_id: :environment do 
        update_tgp_model_id
    end

    task process_tgp_models: :environment do 
        process_tgp_models
    end

    task delete_bad_tire_models: :environment do
        delete_bad_tire_models
    end

    task tgp_brands: :environment do
        process_tgp_data(true)
    end

    task tgp_brands_test: :environment do
        process_tgp_data(false)
    end

    task load_brands_and_check_existing: :environment do
        process_tgp_data(true)
        check_existing_listings(true)
    end

    task check_existing_listings: :environment do
        check_existing_listings(true)
    end

    task check_existing_listings_no_alt: :environment do
        check_existing_listings(false)
    end

    task fix_tire_sizes: :environment do
        fix_tire_sizes
    end

    task check_tire_model_info: :environment do 
        check_tire_model_info
    end

    task show_tgp_fields: :environment do
        show_tgp_fields
    end

    task update_tire_manufacturers: :environment do
        update_tire_manufacturers
    end
end

def fix_tire_sizes
    sql = "select sizestr, count(*) from tire_sizes group by sizestr having count(*) > 1 order by count(*) desc"
    bad_sizes = TireSize.connection.execute(sql)
    bad_sizes.each do |size|
        good_id = 0
        all_sizes = TireSize.find_all_by_sizestr(size["sizestr"], :order => "created_at")
        all_sizes.each do |s|
            if s == all_sizes.first
                good_id = s.id
            else
                puts "Need to change #{s.id} to #{good_id} (#{s.sizestr}) for tire models"
                tireModels = TireModel.find_all_by_tire_size_id(s.id)
                tireModels.each do |model|
                    puts "changing #{model.id} #{model.name} from #{model.tire_size_id} to #{good_id}"
                    model.tire_size_id = good_id
                    model.save
                end

                puts "Need to change #{s.id} to #{good_id} (#{s.sizestr}) for tire listings"
                tireListings = TireListing.find_all_by_tire_size_id(s.id)
                tireListings.each do |listing|
                    puts "changing #{listing.id} to #{good_id}"
                    listing.tire_size_id = good_id
                    listing.save
                end

                puts "Need to change #{s.id} to #{good_id} (#{s.sizestr}) for auto options"
                autoOptions = AutoOption.find_all_by_tire_size_id(s.id)
                autoOptions.each do |auto_option|
                    puts "changing #{auto_option.id} to #{good_id}"
                    auto_option.tire_size_id = good_id
                    auto_option.save
                end

                s.delete
            end
        end
    end
end

def delete_old_tire_model_infos
end

def check_tire_model_info
    TireModel.all.each do |m|
        if m.tire_model_info.nil?
            puts "#{m.id} #{m.tire_model_info_id} #{m.tire_manufacturer.name} #{m.name} has a NIL model info"
            if !m.tire_model_info_id.nil? && m.tire_model_info_id > 0
                m.tire_model_info_id = -1
                m.save
            end
        elsif m.tire_model_info.tire_model_name != m.name 
            puts "#{m.id} #{m.tire_manufacturer.name} #{m.name} has a model info with name #{m.tire_model_info.tire_model_name}"
            m.tire_model_info.tire_model_name = m.name
            m.tire_model_info.save
        end
    end

    if false
        TireModel.all.each do |m|
            if m.tire_model_info.tire_model_name != m.name 
                m.update_attribute(:name, m.tire_model_info.tire_model_name)
            end
        end
    end
end

def delete_bad_tire_models
    TireModel.all.each do |t|
        if t.updated_at < Date.today - 14.days &&
            !["Barum", "Durun", "Geostar", "Goodride", "Lexani", "Accelera", "Achilles", "Aurora", "Carbon Series", "Doral", "Duran", "Gremax", "Mayrun", "Milestar", "Nankang", "Winrun", "Zeetex"].include?(t.tire_manufacturer.name) &&
            t.manu_part_num.blank? && t.tire_listings.size == 0
            puts "Deleted #{t.tire_manufacturer.name} #{t.name} #{t.tire_size.sizestr} #{t.updated_at}"

            t.destroy
        end
    end
end

def check_existing_listings(show_alt)
    not_yet_found = 0
    found = 0
    TireListing.all.each do |t|
        if !t.tire_model.nil? && t.tire_model.updated_at < Date.today - 14.days &&
            !["Accelera", "Achilles", "Aurora", "Carbon Series", "Doral", "Duran", "Gremax", "Mayrun", "Milestar", "Nankang", "Winrun", "Zeetex"].include?(t.tire_manufacturer.name) &&
            t.tire_model.manu_part_num.blank?

            tire_model = t.tire_model

            similar_tires = TireModel.find(:all, :conditions => ['tire_manufacturer_id = ? and name = ? and tire_size_id = ? and id <> ?', t.tire_model.tire_manufacturer_id, t.tire_model.name, t.tire_model.tire_size_id, t.tire_model.id])

            if t.updated_at <= Date.today - 60.days
                t.destroy
            else
                if show_alt
                    puts "(#{tire_model.id}) #{t.tire_manufacturer.name} #{t.tire_model.name} #{t.tire_model.updated_at} #{t.tire_size.sizestr} manu#: #{t.tire_model.manu_part_num}"
                    puts "     Listing updated: #{t.updated_at}"
                end
                not_yet_found += 1

                if similar_tires && similar_tires.size > 0
                    if !show_alt
                        if t.updated_at <= Date.today - 60.days
                            t.destroy
                        else
                            puts "(#{tire_model.id}) #{t.tire_manufacturer.name} #{t.tire_model.name} #{t.tire_model.updated_at} #{t.tire_size.sizestr} manu#: #{t.tire_model.manu_part_num}"
                            puts "     Listing updated: #{t.updated_at}"
                        end
                    else
                        puts "    This: ID=#{tire_model.id} code=#{tire_model.tire_code} manu=#{tire_model.manu_part_num} listings=#{tire_model.tire_listings.size}"
                        similar_tires.each do |similar_tire|
                            puts "     Alt: ID=#{similar_tire.id} code=#{similar_tire.tire_code} manu=#{similar_tire.manu_part_num} listings=#{similar_tire.tire_listings.size} active=#{similar_tire.active}"
                        end
                    end
                    puts ""
                end
            end
        else
            found += 1
        end
    end
    puts "Not yet found: #{not_yet_found}"
    puts "Found: #{found}"
end

def update_tire_manufacturers
    ["102|Gislaved", "104|Vogue", "106|Ironman", "108|Triangle", "112|Roadmaster","114|Double Coin",
    "118|National","11|Firestone","120|OHTSU", "122|Greenball", "124|Autogrip", "126|Kenda",
    "128|Minos", "12|Pirelli", "130|Vortex", "132|Advanta", "134|Gladiator", "136|Zenna",
    "138|O'Green", "13|Cooper", "142|Blacklion", "144|Aeolus", "146|HIFLY", "148|DYNACARGO",
    "14|General", "150|Duro", "152|Forgiato", "154|WindForce", "157|Landsail", "159|Delinte",
    "15|Dayton", "165|Westlake", "16|Yokohama", "17|Sumitomo", "18|Continental", "19|Michelin",
    "1|Bridgestone", "20|BFGoodrich", "21|Uniroyal", "27|Dean", "28|Falken", "29|Hankook",
    "2|Goodyear", "30|Mastercraft", "31|Maxxis", "32|Nitto", "33|Toyo", "3|Dunlop", "44|Kumho",
    "45|Centennial", "46|Cordovan", "48|Eldorado", "49|Federal", "50|GT Radial", "51|Hercules",
    "52|Jetzon", "53|Merit", "54|Multi-Mile", "60|Sigma", "61|Starfire", "62|Telstar", "63|Vanderbilt",
    "68|Delta", "69|Nokian", "70|Dick Cepek", "71|Mickey Thompson", "76|Fuzion", "78|Riken",
    "80|Nexen", "86|Sailun", "88|Republic", "90|Summit", "92|Runway", "94|Atlas Tires",
    "96|Primewell", "9|Kelly"].each do |num_and_name|
        ar = num_and_name.split("|")
        tire_manu = TireManufacturer.find_by_name(ar[1])
        if tire_manu.nil?
            tire_manu = TireManufacturer.new
            tire_manu.name = ar[1]
        end
        tire_manu.tgp_brand_id = ar[0].to_i 
        tire_manu.save
    end
end

def show_tgp_fields
    f = File.open("./db/tgpBrands_US_1504_pipe_only/tgpBrands_SKU_1504_US_pipe_only.txt", 'r')
    header_line = f.gets.gsub(/\n/, "").gsub(/\r/, "")
    field_names = header_line.split("|")

    lines_read = 0
    while (tire_data_line = f.gets) && lines_read < 100
        lines_read += 1

        tire_data_line = tire_data_line.gsub(/\n/, "").gsub(/\r/, "")

        ar_data = tire_data_line.split("|")

        (0..ar_data.size - 1).each do |i|
            puts field_names[i] + "\t" + ar_data[i]
        end
    end
end

def update_tgp_model_id
    f = File.open("./db/tgpBrands_US_1504_pipe_only/tgpBrands_SKU_1504_US_pipe_only.txt", 'r')
    header_line = f.gets.gsub(/\n/, "").gsub(/\r/, "")
    field_names = header_line.split("|")
    field_hash = {}

    field_hash[:brand_id_field_num] = field_names.index("SKU_BRANDID")
    field_hash[:brand_name_field_num] = field_names.index("SKU_BRANDNAME")
    field_hash[:model_id_field_num] = field_names.index("SKU_MODELID")
    field_hash[:model_name_field_num] = field_names.index("SKU_MODELNAME")
    field_hash[:part_number_field_num] = field_names.index("SKU_PARTNUMBER")
    field_hash[:tire_size_field_num] = field_names.index("SKU_TIRESIZE")
    field_hash[:tire_size_raw_field_num] = field_names.index("SKU_RAWSIZE")
    field_hash[:speed_rating] = field_names.index("SKU_SPEEDRATING")
    field_hash[:revs_per_mile] = field_names.index("SKU_REVSPERMILE")
    field_hash[:load_index] = field_names.index("SKU_LOADINDEX_SINGLE")
    field_hash[:dual_load_index] = field_names.index("SKU_LOADINDEX_DUAL")
    field_hash[:ply] = field_names.index("SKU_PLY")
    field_hash[:speed_rating] = field_names.index("SKU_SPEEDRATING")
    field_hash[:rim_width] = field_names.index("SKU_MEASUREDRIMWIDTH")
    field_hash[:min_rim_width] = field_names.index("SKU_MINRIMWIDTH")
    field_hash[:max_rim_width] = field_names.index("SKU_MAXRIMWIDTH")
    field_hash[:diameter] = field_names.index("SKU_DIAMETER")
    field_hash[:single_max_load_pounds] = field_names.index("SKU_SINGLEMAXLOAD")
    field_hash[:dual_max_load_pounds] = field_names.index("SKU_DUALMAXLOAD")
    field_hash[:single_max_psi] = field_names.index("SKU_SINGLEMAXPSI")
    field_hash[:dual_max_psi] = field_names.index("SKU_DUALMAXPSI")
    field_hash[:section_width] = field_names.index("SKU_SECTIONWIDTH")
    field_hash[:tread_depth] = field_names.index("SKU_TREADDEPTH")
    field_hash[:utqg_temp] = field_names.index("SKU_UTQGTEMP")
    field_hash[:utqg_treadwear] = field_names.index("SKU_UTQGWEAR")
    field_hash[:utqg_traction] = field_names.index("SKU_UTQGTRACTION")
    field_hash[:weight_pounds] = field_names.index("SKU_WEIGHT")
    field_hash[:sidewall] = field_names.index("SKU_SIDEWALL")
    field_hash[:active] = field_names.index("SKU_ACTIVE")
    field_hash[:embedded_speed] = field_names.index("SKU_EMBEDDED_SPEED")
    field_hash[:load_description] = field_names.index("SKU_LOADDESC")
    field_hash[:warranty_miles] = field_names.index("SKU_WARRANTY")
    field_hash[:run_flat_id] = field_names.index("SKU_RUNFLATID")
    field_hash[:tgp_tire_type_id] = field_names.index("SKU_TIRETYPEID")
    field_hash[:tgp_category_id] = field_names.index("SKU_CATEGORYID")
    field_hash[:suffix] = field_names.index("SKU_SUFFIX")
    field_hash[:tire_code] = field_names.index("SKU_PREFIX")

    lines_read = 0

    while (tire_data_line = f.gets)
        lines_read += 1
        tire_data_line = tire_data_line.gsub(/\n/, "").gsub(/\r/, "")

        ar_data = tire_data_line.split("|")

        puts "brand id is #{ar_data[field_hash[:brand_id_field_num]]}"
        tire_manu = TireManufacturer.find_by_tgp_brand_id(ar_data[field_hash[:brand_id_field_num]])
        tire_model = TireModel.find_by_tire_manufacturer_id_and_manu_part_num(tire_manu.id, ar_data[field_hash[:part_number_field_num]]) 

        if !tire_model.nil?
            tire_model.update_attribute(:tgp_model_id, ar_data[field_hash[:model_id_field_num]])
            puts "Updated attribute #{tire_model.id} #{ar_data[field_hash[:model_id_field_num]]}"
        else
            puts "Could not find model..."
        end
    end  
end

def process_tgp_models
    f = File.open("./db/tgpBrands_US_1504_pipe_only/tgpBrands_FB_1504_US_pipe_only.txt", 'r')
    puts "file opened..."

    header_line = f.gets.gsub(/\n/, "").gsub(/\r/, "")
    field_names = header_line.split("|")
    field_hash = {}

    puts "reading header"

    field_hash[:brand_id_field_num] = field_names.index("FB_BRANDID")
    field_hash[:model_id_field_num] = field_names.index("FB_MODELID")
    field_hash[:text_id_field_num] = field_names.index("FB_TEXTID")
    field_hash[:text_field_num] = field_names.index("FB_TEXT")
    field_hash[:type_id_field_num] = field_names.index("FB_TYPEID")
    field_hash[:sequence_id_field_num] = field_names.index("FB_SEQUENCE")

    puts "Got it - #{header_line}"

    lines_read = 0
    while (tire_data_line = f.gets) #&& lines_read < 100
        lines_read += 1

        puts "#{lines_read} read...."

        if !tire_data_line.valid_encoding?
            tire_data_line = tire_data_line.encode("UTF-16be", :invalid=>:replace, :replace=>"?").encode('UTF-8')
        end
        tire_data_line = tire_data_line.gsub(/\n/, "").gsub(/\r/, "")

        ar_data = tire_data_line.split("|")

        tire_manu = TireManufacturer.find_by_tgp_brand_id(ar_data[field_hash[:brand_id_field_num]])
        tire_models = TireModel.find_all_by_tire_manufacturer_id_and_tgp_model_id(tire_manu.id, ar_data[field_hash[:model_id_field_num]])

        if tire_models.nil? || tire_models.first.nil?
            puts "Could not find any models with Model ID=#{ar_data[field_hash[:model_id_field_num]]}"
        else
            ar = tire_models.map(&:tgp_model_id).uniq

            tmi = TireModelInfo.find(tire_models.first.tire_model_info_id)

            if tmi.nil?
                puts "No findy #{ar[0]}"
            else
                #puts "Manu: #{tire_manu.name} #{tire_models.first.name} - #{lines_read} - #{ar_data[field_hash[:text_field_num]]}"
                case ar_data[field_hash[:type_id_field_num]].to_i 
                    when 1
                        # feature
                        tmi.set_tgp_features(ar_data[field_hash[:sequence_id_field_num]].to_i, ar_data[field_hash[:text_field_num]])
                        puts "-----------FEATURES-----------"
                        puts tmi.get_tgp_features
                        puts "------------------------------"
                        tmi.save
                    when 2
                        # benefit
                        tmi.set_tgp_benefits(ar_data[field_hash[:sequence_id_field_num]].to_i, ar_data[field_hash[:text_field_num]])
                        puts "----------BENEFITS--+---------"
                        puts tmi.get_tgp_benefits
                        puts "------------------------------"
                        tmi.save
                    when 7
                        # other feature
                        # benefit
                        tmi.set_tgp_other_attributes(ar_data[field_hash[:sequence_id_field_num]].to_i, ar_data[field_hash[:text_field_num]])
                        puts "----------OTHER--+---------"
                        puts tmi.get_tgp_other_attributes
                        puts "------------------------------"
                        tmi.save
                    when 10
                        # full size image
                        puts "./db/tgpBrands_US_1504_pipe_only/tgpBrands_1504_images_US/#{tire_manu.name.gsub(/ /, '_').gsub(/\'/, '')}/images/#{ar_data[field_hash[:text_field_num]]}"
                        tmi.stock_photo1 = File.open("./db/tgpBrands_US_1504_pipe_only/tgpBrands_1504_images_US/#{tire_manu.name.gsub(/ /, '_').gsub(/\'/, '')}/images/#{ar_data[field_hash[:text_field_num]]}", 'rb')
                        tmi.save
                    when 11
                        # thumbnail image
                end
            end
        end
    end
end

def process_tgp_data(create_records)
    f = File.open("./db/tgpBrands_US_1504_pipe_only/tgpBrands_SKU_1504_US_pipe_only.txt", 'r')
    header_line = f.gets.gsub(/\n/, "").gsub(/\r/, "")
    field_names = header_line.split("|")
    field_hash = {}

    no_manu_found = 0
    no_model_found = 0
    no_model_or_manu_found = 0

    manu_found = 0
    model_found = 0

    manus_not_found = []

    confidence = FuzzyStringMatch::JaroWinkler.create(:pure)

    field_hash[:brand_id_field_num] = field_names.index("SKU_BRANDID")
    field_hash[:brand_name_field_num] = field_names.index("SKU_BRANDNAME")
    field_hash[:model_id_field_num] = field_names.index("SKU_MODELID")
    field_hash[:model_name_field_num] = field_names.index("SKU_MODELNAME")
    field_hash[:part_number_field_num] = field_names.index("SKU_PARTNUMBER")
    field_hash[:tire_size_field_num] = field_names.index("SKU_TIRESIZE")
    field_hash[:tire_size_raw_field_num] = field_names.index("SKU_RAWSIZE")
    field_hash[:speed_rating] = field_names.index("SKU_SPEEDRATING")
    field_hash[:revs_per_mile] = field_names.index("SKU_REVSPERMILE")
    field_hash[:load_index] = field_names.index("SKU_LOADINDEX_SINGLE")
    field_hash[:dual_load_index] = field_names.index("SKU_LOADINDEX_DUAL")
    field_hash[:ply] = field_names.index("SKU_PLY")
    field_hash[:speed_rating] = field_names.index("SKU_SPEEDRATING")
    field_hash[:rim_width] = field_names.index("SKU_MEASUREDRIMWIDTH")
    field_hash[:min_rim_width] = field_names.index("SKU_MINRIMWIDTH")
    field_hash[:max_rim_width] = field_names.index("SKU_MAXRIMWIDTH")
    field_hash[:diameter] = field_names.index("SKU_DIAMETER")
    field_hash[:single_max_load_pounds] = field_names.index("SKU_SINGLEMAXLOAD")
    field_hash[:dual_max_load_pounds] = field_names.index("SKU_DUALMAXLOAD")
    field_hash[:single_max_psi] = field_names.index("SKU_SINGLEMAXPSI")
    field_hash[:dual_max_psi] = field_names.index("SKU_DUALMAXPSI")
    field_hash[:section_width] = field_names.index("SKU_SECTIONWIDTH")
    field_hash[:tread_depth] = field_names.index("SKU_TREADDEPTH")
    field_hash[:utqg_temp] = field_names.index("SKU_UTQGTEMP")
    field_hash[:utqg_treadwear] = field_names.index("SKU_UTQGWEAR")
    field_hash[:utqg_traction] = field_names.index("SKU_UTQGTRACTION")
    field_hash[:weight_pounds] = field_names.index("SKU_WEIGHT")
    field_hash[:sidewall] = field_names.index("SKU_SIDEWALL")
    field_hash[:active] = field_names.index("SKU_ACTIVE")
    field_hash[:embedded_speed] = field_names.index("SKU_EMBEDDED_SPEED")
    field_hash[:load_description] = field_names.index("SKU_LOADDESC")
    field_hash[:warranty_miles] = field_names.index("SKU_WARRANTY")
    field_hash[:run_flat_id] = field_names.index("SKU_RUNFLATID")
    field_hash[:tgp_tire_type_id] = field_names.index("SKU_TIRETYPEID")
    field_hash[:tgp_category_id] = field_names.index("SKU_CATEGORYID")
    field_hash[:suffix] = field_names.index("SKU_SUFFIX")
    field_hash[:tire_code] = field_names.index("SKU_PREFIX")

    lines_read = 0
    can_update = 0
    not_found_by_manu = {}
    found_by_manu = {}

    while (tire_data_line = f.gets)# && lines_read < 5000
        lines_read += 1
        tire_data_line = tire_data_line.gsub(/\n/, "").gsub(/\r/, "")

        ar_data = tire_data_line.split("|")

        tire_manu = TireManufacturer.find_by_tgp_brand_id(ar_data[field_hash[:brand_id_field_num]])

        if tire_manu.nil?
            tire_manu = TireManufacturer.find_by_name(ar_data[field_hash[:brand_name_field_num]])
            if tire_manu.nil? && ar_data[field_hash[:brand_name_field_num]] == "BFGoodrich"
                tire_manu = TireManufacturer.find_by_name("BF Goodrich")
            end
            if tire_manu.nil? && ar_data[field_hash[:brand_name_field_num]] == "Multi-Mile"
                tire_manu = TireManufacturer.find_by_name("MultiMile")
            end
            if tire_manu.nil? && ar_data[field_hash[:brand_name_field_num]] == "OHTSU"
                tire_manu = TireManufacturer.find_by_name("Ohtsu")
            end
        end

        if tire_manu.nil? && create_records
            tire_manu = TireManufacturer.new
            tire_manu.tgp_brand_id = ar_data[field_hash[:brand_id_field_num]]
            tire_manu.name = ar_data[field_hash[:brand_name_field_num]]
            tire_manu.save
        end

        if tire_manu.nil?
            manus_not_found << ar_data[field_hash[:brand_name_field_num]] unless !manus_not_found.index(ar_data[field_hash[:brand_name_field_num]]).nil?
        end

        tire_model = nil
        best_guess = nil
        tire_model = TireModel.find_by_tire_manufacturer_id_and_manu_part_num(tire_manu.id, ar_data[field_hash[:part_number_field_num]]) unless tire_manu.nil?

        ts = ar_data[field_hash[:tire_size_field_num]]
        arSize = /(|P|LT|Z)(\d{3})(\ x|x|\/)(\d{2})(R|ZR|VR|SR|RF|ZRF)(\d{2}(\.5)*)(\/*\w*)/.match(ts)

        if #lines_read < 1000 &&
            !ts.start_with?("30x9.50") && !ts.start_with?("31x10.50") && !ts.start_with?("33x10.50") &&
            !ts.start_with?("33x12.50") && !ts.start_with?("35x12.50") && !ts.start_with?("35x12.50") &&
            !ts.start_with?("33x9.50") && !ts.start_with?("11R22.5") && !ts.start_with?("39x13.50") &&
            !ts.start_with?("9.50R16.5") && !ts.start_with?("37x12.50") && !ts.start_with?("32x11.50") &&
            !ts.start_with?("35x13.50") && !ts.start_with?("7.50R16") && !ts.start_with?("10R22.5") &&
            !ts.start_with?("8.75R16.5") && !ts.start_with?("155R12") && !ts.start_with?("155R13") &&
            !ts.start_with?("165R15") && !ts.start_with?("7.00R15") && !ts.start_with?("27x8.50") &&
            !ts.start_with?("8.75-16.5") && !ts.start_with?("9.50-16.5") && !ts.start_with?("7.50-16") &&
            !ts.start_with?("40x14.50") && !ts.start_with?("31x11.50") && !ts.start_with?("165R13") &&
            !ts.start_with?("12R24.5") && !ts.start_with?("9R22.5") && !ts.start_with?("7.00-15") &&
            !ts.start_with?("175R14") && !ts.start_with?("185R13") && !ts.start_with?("185R14") && 
            !ts.start_with?("40x13.50") && !ts.start_with?("8.00R16.5") && !ts.start_with?("8R17.5") &&
            !ts.start_with?("145R12") && !ts.start_with?("8R19.5") && !ts.start_with?("10.00R20") &&
            !ts.start_with?("145R13") && !ts.start_with?("11R24.5") && !ts.start_with?("42x14.50") &&
            !ts.start_with?("37x13.50") && !ts.start_with?("235-710") && !ts.start_with?("245-680") &&
            !ts.start_with?("225-700") && !ts.start_with?("38x14.50") && !ts.start_with?("8.00-16.5") &&
            !ts.start_with?("11.00R20") && !ts.start_with?("265-790") && !ts.start_with?("12.00R24") &&
            !ts.start_with?("38x15.50") && !ts.start_with?("12R22.5") && !ts.start_with?("11.00R22") &&
            !ts.start_with?("12.00R20") && !ts.start_with?("11.00R24") && !ts.start_with?("8.25R20") &&
            !ts.start_with?("9.00R20") && !ts.start_with?("38x13.50") && !ts.start_with?("205R16") &&
            !ts.start_with?("36x13.50") && !ts.start_with?("40x15.50") && !ts.start_with?("195R14") &&
            !ts.start_with?("33x13.50")

            my_sizestr = "#{arSize[2]}/#{arSize[4]}R#{arSize[6]}"
            if create_records
                puts "Creating #{my_sizestr}"
                tire_size = TireSize.find_or_create_by_sizestr(my_sizestr)
            else
                tire_size = TireSize.find_by_sizestr(my_sizestr)
            end

            if tire_size.nil?
                puts "Could not find size: #{my_sizestr}"
            end

            if tire_manu.nil? || true
                con = nil

                if !create_records &&tire_model.nil? && !tire_manu.nil? && !tire_size.nil?
                    tire_model = TireModel.find(:first, :conditions => ["tire_manufacturer_id = ? and tire_size_id = ? and name ilike ? and speed_rating in ('', ?)", tire_manu.id, tire_size.id, ar_data[field_hash[:model_name_field_num]], ar_data[field_hash[:speed_rating]]])
                    if tire_model.nil? && !create_records
                        matcher = FuzzyMatch.new(TireModel.find(:all,  :conditions => ["tire_manufacturer_id = ? and tire_size_id = ? and manu_part_num = ''", tire_manu.id, tire_size.id]), :read => :name)
                        best_guess = matcher.find(ar_data[field_hash[:model_name_field_num]])
                        if best_guess
                            # check our confidence score
                            con = confidence.getDistance(best_guess.name.downcase, ar_data[field_hash[:model_name_field_num]].downcase)
                            if con > 0.95
                            else
                                best_guess = nil
                            end
                        end
                    end
                end

                puts "Line: #{lines_read}"
                puts "Brand Name: #{ar_data[field_hash[:brand_name_field_num]]} - #{!tire_manu.nil?}"
                puts "Model ID: #{ar_data[field_hash[:model_id_field_num]]}"
                puts "Model Name: #{ar_data[field_hash[:model_name_field_num]]} - #{!tire_model.nil?} #{tire_model.nil? ? '' : tire_model.id}"
                if !best_guess.nil?
                    puts "     Best Guess Model Name: #{best_guess.name} - #{best_guess.manu_part_num} (#{con.nil? ? '' : con}) - #{best_guess.tire_code}#{best_guess.tire_size.sizestr}"
                    if best_guess.name.downcase == ar_data[field_hash[:model_name_field_num]].downcase
                        if create_records
                            best_guess.update_attribute(:tire_code, arSize[1])
                            if best_guess.manu_part_num.blank? && best_guess.tire_size.sizestr.downcase == my_sizestr.downcase
                                best_guess.update_attribute(:manu_part_num, ar_data[field_hash[:part_number_field_num]]) 
                            else
                                puts "**** not eligible for manu_part_num update ***"
                            end
                        else
                            puts "**** need to update ****"
                            can_update += 1
                            if best_guess.manu_part_num.blank? && best_guess.tire_size.sizestr.downcase == my_sizestr.downcase
                            else
                                puts "**** not eligible for manu_part_num update ***"
                            end
                        end
                    end
                end
                puts "Part Number: #{ar_data[field_hash[:part_number_field_num]]}"

                if create_records && tire_model.nil?
                    # create one 
                    tire_model = TireModel.new
                    tire_model.tire_manufacturer_id = tire_manu.id
                    tire_model.name = ar_data[field_hash[:model_name_field_num]]
                    tire_model.tire_size_id = tire_size.id
                    tire_model.manu_part_num = ar_data[field_hash[:part_number_field_num]]

                end
                if !tire_model.nil?
                    # is the size of what we already have consistent with TGP data?
                    if ar_data[field_hash[:tire_size_raw_field_num]] != tire_model.tire_size.sizestr &&
                        !tire_size.nil?

                        if create_records
                            tire_model.tire_size_id = tire_size.id
                            tire_model.update_attribute(:tire_size_id, tire_size.id)
                        end
                    end

                    #if tire_model.tire_code != arSize[1] && create_records
                    #    tire_model.update_attribute(:tire_code, arSize[1])
                    #end

                    #tire_model.touch if create_records

                    if !create_records
                        similar_tires = TireModel.find(:all, :conditions => ['tire_manufacturer_id = ? and name = ? and tire_size_id = ? and id <> ?', tire_model.tire_manufacturer_id, tire_model.name, tire_model.tire_size_id, tire_model.id])
                        if similar_tires && similar_tires.size > 0
                            puts "    This: ID=#{tire_model.id} code=#{tire_model.tire_code} manu=#{tire_model.manu_part_num} listings=#{tire_model.tire_listings.size}"
                            similar_tires.each do |similar_tire|
                                if similar_tire.updated_at < Date.today - 5.days &&
                                    similar_tire.manu_part_num.blank? &&
                                    similar_tire.tire_listings.size == 0
                                    puts "  DELETE: ID=#{similar_tire.id} code=#{similar_tire.tire_code} manu=#{similar_tire.manu_part_num} listings=#{similar_tire.tire_listings.size} updated=#{similar_tire.updated_at}"
                                    similar_tire.delete
                                else
                                    puts "     Alt: ID=#{similar_tire.id} code=#{similar_tire.tire_code} manu=#{similar_tire.manu_part_num} listings=#{similar_tire.tire_listings.size}"
                                end
                            end
                        end
                    else
                        # now update all the attributes of the tire model
                        tire_model.sidewall = ar_data[field_hash[:sidewall]]
                        tire_model.utqg_temp = ar_data[field_hash[:utqg_temp]]
                        tire_model.utqg_traction = ar_data[field_hash[:utqg_traction]]
                        tire_model.utqg_treadwear = ar_data[field_hash[:utqg_treadwear]]
                        tire_model.load_index = ar_data[field_hash[:load_index]]
                        tire_model.rim_width = ar_data[field_hash[:rim_width]]
                        tire_model.speed_rating = ar_data[field_hash[:speed_rating]]
                        tire_model.tread_depth = ar_data[field_hash[:tread_depth]]
                        tire_model.tire_category_id = tire_model.translate_tgp_category_id(ar_data[field_hash[:tgp_category_id]])
                        tire_model.product_code = ar_data[field_hash[:part_number_field_num]]
                        tire_model.weight = ar_data[field_hash[:weight_pounds]]
                        tire_model.weight_pounds = ar_data[field_hash[:weight_pounds]]
                        tire_model.warranty_miles = ar_data[field_hash[:warranty_miles]]
                        tire_model.tire_code = ar_data[field_hash[:tire_code]]
                        tire_model.ply = ar_data[field_hash[:ply]]
                        tire_model.diameter = ar_data[field_hash[:diameter]]
                        tire_model.revs_per_mile = ar_data[field_hash[:revs_per_mile]]
                        tire_model.min_rim_width = ar_data[field_hash[:min_rim_width]]
                        tire_model.max_rim_width = ar_data[field_hash[:max_rim_width]]
                        tire_model.single_max_load_pounds = ar_data[field_hash[:single_max_load_pounds]]
                        tire_model.dual_max_load_pounds = ar_data[field_hash[:dual_max_load_pounds]]
                        tire_model.single_max_psi = ar_data[field_hash[:single_max_psi]]
                        tire_model.dual_max_psi = ar_data[field_hash[:dual_max_psi]]
                        tire_model.section_width = ar_data[field_hash[:section_width]]
                        tire_model.active = (ar_data[field_hash[:active]].to_i == 0 ? false : true)
                        tire_model.embedded_speed = ar_data[field_hash[:embedded_speed]]
                        tire_model.load_description = ar_data[field_hash[:load_description]]
                        tire_model.tgp_category_id = ar_data[field_hash[:tgp_category_id]]
                        tire_model.run_flat_id = ar_data[field_hash[:run_flat_id]]
                        tire_model.tgp_tire_type_id = ar_data[field_hash[:tgp_tire_type_id]]
                        tire_model.dual_load_index = ar_data[field_hash[:dual_load_index]]
                        tire_model.suffix = ar_data[field_hash[:suffix]]

                        tire_model.save
                    end
                end
                puts "------------------------------------------------------------"
            end

            if tire_manu.nil?
                not_found_by_manu[ar_data[field_hash[:brand_name_field_num]]] = 0 if not_found_by_manu[ar_data[field_hash[:brand_name_field_num]]].nil?
                not_found_by_manu[ar_data[field_hash[:brand_name_field_num]]] += 1
            elsif tire_model.nil?
                not_found_by_manu[ar_data[field_hash[:brand_name_field_num]]] = 0 if not_found_by_manu[ar_data[field_hash[:brand_name_field_num]]].nil?
                not_found_by_manu[ar_data[field_hash[:brand_name_field_num]]] += 1
            else
                found_by_manu[ar_data[field_hash[:brand_name_field_num]]] = 0 if found_by_manu[ar_data[field_hash[:brand_name_field_num]]].nil?
                found_by_manu[ar_data[field_hash[:brand_name_field_num]]] += 1
            end

            no_manu_found += 1 if tire_manu.nil?
            no_model_found += 1 if tire_model.nil? && !tire_manu.nil?
            no_model_or_manu_found += 1 if tire_manu.nil? && tire_model.nil?

            manu_found += 1 unless tire_manu.nil?
            model_found += 1 unless tire_model.nil?
        end
    end

    puts "Manu found: #{manu_found}"
    puts "Manu not found: #{no_manu_found}"
    puts "Model found: #{model_found}"
    puts "Model not found: #{no_model_found}"
    puts "Model and manu not found: #{no_model_or_manu_found}"

    if !create_records
        puts ""
        puts "Eligible to update manu part num: #{can_update}"
    end


    puts ""
    puts "Bad manus:"
    puts manus_not_found.join("\n")

    puts ""
    puts "Found:"
    found_by_manu.each do |k, v|
        puts "#{k} - #{v}"
    end

    puts ""
    puts "Not Found:"
    not_found_by_manu.each do |k, v|
        puts "#{k} - #{v}"
    end
end
