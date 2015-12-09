require 'roo'

namespace :LoadGlobalSpreadsheet do
    desc "Load tire information from Global's spreadsheet"
    task populate: :environment do
        store = TireStore.find_all_by_name("Global Tires Plus").last

        puts "Processing store #{store.id}"

        ts = nil
        s = Google.new("0Are82DpPuAZ3dDI2TVZwQUVKcXVnOFZSLS0tLU9wNmc", google_docs_username(), google_docs_password())
        (s.first_row..s.last_row).each do |i|
            curRawSize = s.cell(i, "A")
            if curRawSize.to_s.size > 0
                x = curRawSize.to_i.to_s
                sizestr = "#{x[0..2]}/#{x[3..4]}R#{x[5..6]}"
                ts = TireSize.find_by_sizestr(sizestr)
                if ts 
                    #puts "Found #{x}"
                end
            end

            if ts && s.cell(i, "E").to_i > 0
                manu_str = s.cell(i, "B")
                model_str = s.cell(i, "C")

                manu = TireManufacturer.find_by_name(manu_str.strip().capitalize())

                if manu
                    if model_str && model_str.strip.size > 0
                        #puts "Need to process #{manu.name} #{model_str} #{ts.sizestr}"

                        tm = TireModel.find_by_tire_manufacturer_id_and_tire_size_id_and_name(manu.id, ts.id, model_str.strip)

                        if tm
                            if s.cell(i, "K") && s.cell(i, "K").include?("http://www.treadhunter.com/tire-listings")
                                puts "Skipping row #{i} because we already processed it"
                            else
                                puts "All good on #{manu.name} #{model_str} #{ts.sizestr}"
                                tl = TireListing.new
                                tl.tire_store_id = store.id
                                tl.tire_manufacturer_id = manu.id
                                tl.tire_model_id = tm.id
                                tl.tire_size_id = ts.id
                                tl.is_new = true
                                tl.quantity = s.cell(i, "E").to_i
                                if tl.quantity > 4
                                    tl.quantity = 4
                                end
                                tl.includes_mounting = false
                                tl.price = s.cell(i, "H").to_f
                                tl.start_date = Time.now
                                tl.save

                                if Rails.env.production?
                                    s.set_value(i, "K", "http://www.treadhunter.com/tire-listings/#{tl.id}")
                                    s.set_value(i, "L", "Created - #{Time.now.to_s}")
                                end
                            end
                        else
                            if TireModel.find_by_tire_manufacturer_id_and_name(manu.id, model_str.strip)
                                puts "*** Could not find #{manu.name} #{model_str} in size #{ts.sizestr}"
                                if Rails.env.production?
                                    s.set_value(i, "L", "Model OK, size not found")
                                end
                            else
                                puts "****Could not find model #{model_str} for #{manu.name}"
                                if Rails.env.production?
                                    s.set_value(i, "L", "Model not found")
                                end
                            end
                        end
                    else
                        puts "Row #{i} - no model found"
                        #s.set_value(i, "L", "No model specified")
                        if Rails.env.production?
                            s.set_value(i, "L", "Model not specified")
                        end
                    end
                else
                    ###puts "couldn't find manufacturer #{manu_str}"
                    if Rails.env.production?
                        s.set_value(i, "L", "Manufacturer not found")
                    end
                end
            else
                #s.set_value(i, "L", "Size not in database")
                if Rails.env.production?
                    s.set_value(i, "L", "Invalid size")
                end
            end
        end
    end
end


namespace :ShowMissingSizesFromGlobalSpreadsheet do
    desc "Show sizes that are missing from Global's spreadsheet"
    task populate: :environment do
        missing_sizes = []

        store = TireStore.find_all_by_name("Global Tires Plus").last

        puts "Processing store #{store.id}"

        ts = nil
        s = Google.new("0Are82DpPuAZ3dDI2TVZwQUVKcXVnOFZSLS0tLU9wNmc", google_docs_username(), google_docs_password())
        (s.first_row..s.last_row).each do |i|
            curRawSize = s.cell(i, "A")
            if curRawSize.to_s.size > 0
                x = curRawSize.to_i.to_s
                sizestr = "#{x[0..2]}/#{x[3..4]}R#{x[5..6]}"
                ts = TireSize.find_by_sizestr(sizestr)
                if ts 
                    #puts "Found #{x}"
                end
            end

            if ts && s.cell(i, "E").to_i > 0
                manu_str = s.cell(i, "B")
                model_str = s.cell(i, "C")

                manu = TireManufacturer.find_by_name(manu_str.strip().capitalize())

                if manu
                    if model_str && model_str.strip.size > 0
                        #puts "Need to process #{manu.name} #{model_str} #{ts.sizestr}"

                        tm = TireModel.find_by_tire_manufacturer_id_and_tire_size_id_and_name(manu.id, ts.id, model_str.strip)

                        if !tm
                            if TireModel.find_by_tire_manufacturer_id_and_name(manu.id, model_str.strip)
                                key = "#{manu.name} #{model_str.strip()} #{ts.sizestr}"
                                if !missing_sizes.include?(key)
                                    missing_sizes << key
                                end
                            end
                        end
                    end
                end
            end
        end
        missing_sizes.sort.each do |m|
            puts m 
        end
    end
end