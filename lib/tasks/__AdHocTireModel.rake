require 'nokogiri'
require 'open-uri'


namespace :AdHocTireModel do
    desc "Create tire model data by hand"
    task populate: :environment do
        [
            {
                :tire_make_str => "Toyo", :tire_model_str => "Proxes T1R", :tire_size_str => "195/45R15",
                :load_index => "78", :speed_rating => "V", :treadwear => "280", :traction => "AA",
                :temperature => "A", :sidewall => "", :rim_width => "", :orig_tread_depth => "10",
                :category_name => ""
            }
        ].each do |h| 
            tire_make_str = h[:tire_make_str]
            tire_size_str = h[:tire_size_str]
            tire_model_str = h[:tire_model_str]
            speed_rating = h[:speed_rating]
            load_index = h[:load_index]
            treadwear = h[:treadwear]
            traction = h[:traction]
            temperature = h[:temperature]
            sidewall = h[:sidewall]
            rim_width = h[:rim_width]
            orig_tread_depth = h[:orig_tread_depth]
            category_name = h[:category_name]

            manu = TireManufacturer.find_or_create_by_name(tire_make_str)
            if !manu
                raise "Could not find #{tire_make_str}"
            end

            tiresize = TireSize.find_or_create_by_sizestr(tire_size_str)
            category = TireCategory.find_or_create_by_category_name(category_name) if category_name != ""

            tire_model = TireModel.find_or_create_by_tire_manufacturer_id_and_tire_size_id_and_name(manu.id, tiresize.id, tire_model_str)
            tire_model.utqg_temp = temperature
            tire_model.utqg_traction = traction
            tire_model.utqg_treadwear = treadwear
            tire_model.load_index = load_index
            tire_model.rim_width = rim_width
            tire_model.speed_rating = speed_rating
            tire_model.tread_depth = orig_tread_depth
            tire_model.tire_category_id = category.id if category
            tire_model.sidewall = sidewall
            tire_model.save

            puts tire_model
        end
    end
end


namespace :AdHocTireModelInfo do
    desc "Create tire model info data by hand"
    task populate: :environment do
        tire_make_str = "Goodyear"
        tire_model_str = "Eagle GT II"
        photo_url = "http://www.thetirestore.com/Goodyear/EagleGTII-tire.jpg"
        
        manu = TireManufacturer.find_by_name(tire_make_str)
        if !manu
            raise "Could not find #{tire_make_str}"
        end

        tmi = TireModelInfo.find_or_create_by_tire_manufacturer_id_and_tire_model_name(manu.id, tire_model_str)
        tmi.photo1_url = photo_url
        tmi.save
    end
end


namespace :AdHocTireModelNational do
    desc "Create tire model data by hand for National"
    task populate: :environment do
        [
            {
                :tire_make_str => "National", :tire_model_str => "XT4000", 
                :product_code => "11541444",
                :tire_size_str => "185/75R14", :load_index => "", :speed_rating => "", 
                :treadwear => "440", 
                :traction => "A", 
                :temperature => "B", 
                :sidewall => "BW", :rim_width => "", :orig_tread_depth => "10", :category_name => ""
            },
            {
                :tire_make_str => "National", :tire_model_str => "XT4000", 
                :product_code => "11541544",
                :tire_size_str => "195/75R14", :load_index => "", :speed_rating => "", 
                :treadwear => "440", 
                :traction => "A", 
                :temperature => "B", 
                :sidewall => "BW", :rim_width => "", :orig_tread_depth => "10", :category_name => ""
            },
            {
                :tire_make_str => "National", :tire_model_str => "XT4000", 
                :product_code => "11541744",
                :tire_size_str => "215/70R14", :load_index => "", :speed_rating => "", 
                :treadwear => "440", 
                :traction => "A", 
                :temperature => "B", 
                :sidewall => "BW", :rim_width => "", :orig_tread_depth => "10", :category_name => ""
            },
            {
                :tire_make_str => "National", :tire_model_str => "XT4000", 
                :product_code => "11542854",
                :tire_size_str => "225/75R15", :load_index => "102", :speed_rating => "S", 
                :treadwear => "440", 
                :traction => "A", 
                :temperature => "B", 
                :sidewall => "BW", :rim_width => "", :orig_tread_depth => "11", :category_name => ""
            },
            {
                :tire_make_str => "National", :tire_model_str => "XT4000", 
                :product_code => "40118",
                :tire_size_str => "205/70R15", :load_index => "95", :speed_rating => "S", 
                :treadwear => "440", 
                :traction => "A", 
                :temperature => "B", 
                :sidewall => "WW", :rim_width => "", :orig_tread_depth => "10", :category_name => ""
            },
            {
                :tire_make_str => "National", :tire_model_str => "XT4000", 
                :product_code => "11543854",
                :tire_size_str => "225/70R15", :load_index => "100", :speed_rating => "S", 
                :treadwear => "440", 
                :traction => "A", 
                :temperature => "B", 
                :sidewall => "BW", :rim_width => "", :orig_tread_depth => "10", :category_name => ""
            },

            {
                :tire_make_str => "National", :tire_model_str => "Durun F-One", 
                :product_code => "11299115",
                :tire_size_str => "255/30R24", :load_index => "97", :speed_rating => "V", 
                :treadwear => "320", 
                :traction => "A", 
                :temperature => "A", 
                :sidewall => "BW", :rim_width => "", :orig_tread_depth => "11", :category_name => ""
            },

            {
                :tire_make_str => "National", :tire_model_str => "Sentinel UN99", 
                :product_code => "12990210",
                :tire_size_str => "225/65R17", :load_index => "102", :speed_rating => "T", 
                :treadwear => "440", 
                :traction => "A", 
                :temperature => "B", 
                :sidewall => "BW", :rim_width => "", :orig_tread_depth => "11", :category_name => ""
            },

            {
                :tire_make_str => "National", :tire_model_str => "Rotalla F106", 
                :product_code => "11299527",
                :tire_size_str => "205/55R16", :load_index => "91", :speed_rating => "W", 
                :treadwear => "340", 
                :traction => "A", 
                :temperature => "A", 
                :sidewall => "BW", :rim_width => "", :orig_tread_depth => "10", :category_name => ""
            },
            {
                :tire_make_str => "National", :tire_model_str => "Rotalla F106", 
                :product_code => "11299528",
                :tire_size_str => "215/55R16", :load_index => "97", :speed_rating => "W", 
                :treadwear => "340", 
                :traction => "A", 
                :temperature => "A", 
                :sidewall => "BW", :rim_width => "", :orig_tread_depth => "10", :category_name => ""
            },
            {
                :tire_make_str => "National", :tire_model_str => "Rotalla F106", 
                :product_code => "11299529",
                :tire_size_str => "225/55R16", :load_index => "99", :speed_rating => "W", 
                :treadwear => "340", 
                :traction => "A", 
                :temperature => "A", 
                :sidewall => "BW", :rim_width => "", :orig_tread_depth => "10", :category_name => ""
            },
            {
                :tire_make_str => "National", :tire_model_str => "Rotalla F106", 
                :product_code => "11299530",
                :tire_size_str => "205/50R16", :load_index => "87", :speed_rating => "W", 
                :treadwear => "340", 
                :traction => "A", 
                :temperature => "A", 
                :sidewall => "BW", :rim_width => "", :orig_tread_depth => "10", :category_name => ""
            },
            {
                :tire_make_str => "National", :tire_model_str => "Rotalla F106", 
                :product_code => "11299439",
                :tire_size_str => "215/40R17", :load_index => "87", :speed_rating => "W", 
                :treadwear => "340", 
                :traction => "A", 
                :temperature => "A", 
                :sidewall => "BW", :rim_width => "", :orig_tread_depth => "10", :category_name => ""
            },
            {
                :tire_make_str => "National", :tire_model_str => "Rotalla F106", 
                :product_code => "11299441",
                :tire_size_str => "225/45R18", :load_index => "95", :speed_rating => "W", 
                :treadwear => "340", 
                :traction => "A", 
                :temperature => "A", 
                :sidewall => "BW", :rim_width => "", :orig_tread_depth => "10", :category_name => ""
            },
            {
                :tire_make_str => "National", :tire_model_str => "Rotalla F106", 
                :product_code => "11299445",
                :tire_size_str => "235/40R18", :load_index => "95", :speed_rating => "W", 
                :treadwear => "340", 
                :traction => "A", 
                :temperature => "A", 
                :sidewall => "BW", :rim_width => "", :orig_tread_depth => "10", :category_name => ""
            },
            {
                :tire_make_str => "National", :tire_model_str => "Rotalla F106", 
                :product_code => "11299448",
                :tire_size_str => "225/35R20", :load_index => "90", :speed_rating => "W", 
                :treadwear => "340", 
                :traction => "A", 
                :temperature => "A", 
                :sidewall => "BW", :rim_width => "", :orig_tread_depth => "10", :category_name => ""
            },
            {
                :tire_make_str => "National", :tire_model_str => "Rotalla F106", 
                :product_code => "11299449",
                :tire_size_str => "245/35R20", :load_index => "95", :speed_rating => "W", 
                :treadwear => "340", 
                :traction => "A", 
                :temperature => "A", 
                :sidewall => "BW", :rim_width => "", :orig_tread_depth => "10", :category_name => ""
            },
            {
                :tire_make_str => "National", :tire_model_str => "Rotalla F106", 
                :product_code => "11299450",
                :tire_size_str => "255/35R20", :load_index => "97", :speed_rating => "W", 
                :treadwear => "340", 
                :traction => "A", 
                :temperature => "A", 
                :sidewall => "BW", :rim_width => "", :orig_tread_depth => "10", :category_name => ""
            }
        ].each do |h| 
            tire_make_str = h[:tire_make_str]
            tire_size_str = h[:tire_size_str]
            tire_model_str = h[:tire_model_str]
            speed_rating = h[:speed_rating]
            load_index = h[:load_index]
            treadwear = h[:treadwear]
            traction = h[:traction]
            temperature = h[:temperature]
            sidewall = h[:sidewall]
            rim_width = h[:rim_width]
            orig_tread_depth = h[:orig_tread_depth]
            category_name = h[:category_name]
            product_code = h[:product_code]

            manu = TireManufacturer.find_or_create_by_name(tire_make_str)
            if !manu
                raise "Could not find #{tire_make_str}"
            end

            puts "#{tire_model_str} #{tire_size_str}"

            tmi = TireModelInfo.find_or_create_by_tire_manufacturer_id_and_tire_model_name(manu.id, tire_model_str)

            tiresize = TireSize.find_or_create_by_sizestr(tire_size_str)
            category = TireCategory.find_or_create_by_category_name(category_name) if category_name != ""

            tire_model = TireModel.find_or_create_by_tire_manufacturer_id_and_tire_size_id_and_name(manu.id, tiresize.id, tire_model_str)
            tire_model.utqg_temp = temperature
            tire_model.utqg_traction = traction
            tire_model.utqg_treadwear = treadwear
            tire_model.load_index = load_index
            tire_model.rim_width = rim_width
            tire_model.speed_rating = speed_rating
            tire_model.tread_depth = orig_tread_depth
            tire_model.tire_category_id = category.id if category
            tire_model.sidewall = sidewall
            tire_model.product_code = product_code
            tire_model.tire_model_info_id = tmi.id
            tire_model.save
        end
    end
end