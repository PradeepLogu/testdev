require 'nokogiri'
require 'open-uri'

def ReadData(url)
    RestClient.get url, :user_agent => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) "
    #open(url, :proxy => "http://54.243.138.45:80", "User-Agent" => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) ").read
end

namespace :ScrapeTireRackModelInfo do
    desc "Create tire manufacturers data"
    task populate: :environment do
        tire_make = "Hankook"
        tire_model = "Dynapro AT RF08"

        #model_url = "http://www.tirerack.com/tires/tires.jsp?tireMake=#{tire_make}&tireModel=#{tire_model}"
        #model_url = "http://www.tirerack.com/tires/tires.jsp?tireMake=Continental&tireModel=ContiProContact+SSR"
        model_url = "http://www.tirerack.com/tires/tires.jsp?tireMake=Hankook&tireModel=Dynapro+AT+RF08"
        #model_url = URI::encode(model_url)
        
        #model_url = "http://www.tirerack.com/tires/tires.jsp?tireMake=Michelin&tireModel=Energy+Saver+A%2FS"

        puts "Reading #{model_url}..."
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
            html_data = Nokogiri::HTML(model_response.to_s)

            html_data.xpath("//div[@class='headers makemodelheader']/h1/text()[2]").each do |tire_manu|
                manu = TireManufacturer.find_or_create_by_name(tire_make)

                category = nil
                html_data.xpath("//div[@class='headers makemodelheader']/h1/span/a/text()").each do |tire_cat|
                    category = TireCategory.find_or_create_by_category_name(tire_cat.text())
                end

                sidewall = ''
                html_data.xpath("//div[@id='sidewallBox']/span/text()").each do |s|
                    sidewall = s.text().strip()
                end

                html_data.xpath("//table[@class='spectable']/tbody/tr").each do |tire_size_row|
                    begin
                        # this gives us each row from the specifications table, now we need to process
                        # each <td> from it to get size and specs

                        tire_size_columns = tire_size_row.xpath(".//td")
                        sizestr = tire_size_columns[0].xpath(".//div/a/strong").text().strip()

                        m = /(\d{2,})\/(\d{2,}).*R(\d{2,})/.match(sizestr)
                        if m && m.size > 0
                            size = m[0].gsub(/ZR/, 'R')
                        end

                        load_index = tire_size_columns[0].xpath(".//a/span/b[contains(., 'Load Index')]")[0].text().strip().gsub('Load Index ', '')
                        speed_rating = tire_size_columns[0].xpath(".//a/span/b[contains(., 'Speed Rating')]")[0].text().strip().gsub('Speed Rating ', '').gsub!(/\W/, '')
                        treadwear = traction = temperature = ''
                        begin
                            treadwear = tire_size_columns[1].xpath(".//a/span/b[contains(., 'Treadwear')]")[0].next_sibling().text().strip()
                            traction = tire_size_columns[1].xpath(".//a/span/b[contains(., 'Traction')]")[0].next_sibling().text().strip()
                            temperature = tire_size_columns[1].xpath(".//a/span/b[contains(., 'Temperature')]")[0].next_sibling().text().strip()
                        rescue
                        end

                        max_load = ''
                        begin
                            max_load = tire_size_columns[2].text().strip()
                        rescue
                        end

                        orig_tread_depth = tire_size_columns[4].text().strip().gsub(/\/32"/i, '')
                        rim_width = tire_size_columns[7].text().strip().gsub(/\"/i, '')

                        puts "size: #{size}, treadwear: #{treadwear}, traction: #{traction}, temperature: #{temperature}"
                        puts "max load: #{max_load} load_description: #{load_index} speed_rating: #{speed_rating}"
                        puts "orig depth: #{orig_tread_depth} rim width: #{rim_width} sidewall: #{sidewall}"
                        puts "-------------------"

                        # now create records
                        tiresize = TireSize.find_or_create_by_sizestr(size)

                        tiremodel  = TireModel.find_by_tire_manufacturer_id_and_tire_size_id_and_name(manu.id, tiresize.id, tire_model)
                        if !tiremodel
                            # gotta create one...
                            tiremodel = TireModel.create(:tire_manufacturer_id => manu.id,
                                                            :tire_size_id => tiresize.id,
                                                            :name => tire_model)
                            puts "Created tire model."
                        else
                            puts "Tire model already found."
                        end

                        #update attributes
                        tiremodel.sidewall = sidewall
                        tiremodel.utqg_temp = temperature
                        tiremodel.utqg_traction = traction
                        tiremodel.utqg_treadwear = treadwear
                        tiremodel.load_index = load_index
                        tiremodel.rim_width = rim_width
                        tiremodel.speed_rating = speed_rating
                        tiremodel.tread_depth = orig_tread_depth
                        tiremodel.tire_category_id = category.id

                        tiremodel.save

                        #puts "Size: #{tire_size_columns[0].xpath}"
                        #tire_size_columns.each do |x|
                        #    puts x.text().strip()
                        #    puts "****"
                        #end
                        #puts "------------------"
                    rescue Exception => e
                        puts "exception #{e.to_s}"
                    end
                end
            end
        else
            puts "Unable to read URL: #{model_url}.  Please check this URL to see if make and model were entered correctly."
        end
    end
end