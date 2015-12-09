require 'nokogiri'
require 'rest_client'

namespace :ScrapeTireMonkey do
    desc "Get tire information from TireMonkey.com"
    task populate: :environment do
        brands = ["Mastercraft", "Goodyear", "Uniroyal", "Cooper",
                    "Firestone", "Continental", "Kumho", "Yokohama",
                    "Michelin", "Kelly", "Falken", "Hankook",
                    "Bridgestone", "General", "MultiMile", "BF Goodrich",
                    "Fuzion", "Toyo", "GT Radial", "Nexen", "Federal",
                    "Cordovan", "Dunlop", "Pirelli", "Sumitomo", "Nitto",
                    "Vanderbilt", "Telstar"]

        brands.each do |brand|
            manu = TireManufacturer.find_by_name(brand)
            if manu.nil?
                puts "Creating new manufacturer record for " + brand
                manu = TireManufacturer.new(:name => brand)
                manu.save
            end

            # Now scrape TireMonkey's "Inventory" page to get list of tire models
            # for this manufacturer
            inventory_url = "http://www.tiremonkey.com/Inventory/" + brand + ".aspx"
            inventory_url = inventory_url.gsub(/[' ']/, '%20')

            inventory_response = RestClient.get inventory_url
            html_tire_models = Nokogiri::HTML(inventory_response.to_s)

            html_tire_models.xpath("//div[@class='tireline']/a").each do |model|
                puts brand + " " +  model.text.strip

                # now we can open each of these pages and get the available sizes
                # for those tires
                model_url = "http://www.tiremonkey.com/Inventory/" + model.attribute("href")
                model_url = model_url.gsub(/[' ']/, '%20')

                puts model_url

                begin
                    model_response = RestClient.get model_url
                    html_model = Nokogiri::HTML(model_response.to_s)

                    attributes = []

                    html_model.xpath("//table[@id='sizesavailable']").each do |sizetable|
                        # first, get attributes
                        sizetable.xpath("//tr/td").each do |attr_name|
                            attributes << attr_name.text.strip.split.join("_").gsub(/[.]/, '')
                        end
                        sizetable.xpath("//tr").each do |sizerow|
                            i = 0

                            temp_model = TireModel.new
                            temp_model.tire_manufacturer_id = manu.id
                            temp_model.name = model.text.strip

                            begin
                                # if we can't parse the attributes, just skip it..
                                sizerow.xpath("td").each do |detail|
                                    #puts attributes[i] + " = " + detail.text.strip

                                    # now we have information about this tire...let's see if we
                                    # have a model
                                    case attributes[i].downcase
                                    when "size"
                                        m1 = /(\d{2,})\/(\d{2,}).*?(\d{2,})/.match(detail.text.strip)
                                        sizestr = m1[1] + '/' + m1[2] + 'R' + m1[3]
                                        tire_size = TireSize.find_or_create_by_sizestr(sizestr)
                                        temp_model.tire_size_id = tire_size.id
                                    when "load_index"
                                        temp_model.load_index = detail.text.strip
                                    when "speed_rating"
                                        temp_model.speed_rating = detail.text.strip
                                    when "rim_width"
                                        temp_model.rim_width = detail.text.strip
                                    when "tread_depth"
                                        temp_model.tread_depth = detail.text.strip
                                    when "utqg_tread_ware"
                                        temp_model.utqg_treadwear = detail.text.strip
                                    when "utqg_temp"
                                        temp_model.utqg_temp = detail.text.strip
                                    when "utqg_traction"
                                        temp_model.utqg_traction = detail.text.strip
                                    when "sidewall"
                                        temp_model.sidewall = detail.text.strip
                                    else
                                        puts "**** what the heck is a " + attributes[i] + "?"
                                    end

                                    i += 1
                                end

                                if !temp_model.tire_size_id.nil?
                                    # now we have a tire_model.  Let's see if it exists, if not create a new one.
                                    tire_model = TireModel.find_by_tire_manufacturer_id_and_name_and_tire_size_id(temp_model.tire_manufacturer_id,
                                                        temp_model.name, temp_model.tire_size_id)
                                    if tire_model.nil?
                                        temp_model.save
                                    else
                                        puts "**** already found this tire."
                                    end
                                end
                            rescue Exception => e
                                puts "Could not parse a row..." + e.message
                                puts model_url # e.backtrace
                            end
                        end
                    end
                rescue Exception => e
                    puts "**** ERROR PARSING PAGE " + e.message
                end
            end
        end
    end
end
