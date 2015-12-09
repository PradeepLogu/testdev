require 'nokogiri'
#require 'rest_client'
require 'open-uri'

def ReadData(url)
    #RestClient.get url, :user_agent => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) "
    open(url, :proxy => "http://54.243.138.45:80", "User-Agent" => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) ").read
end

namespace :ScrapeTireRack do
    desc "Get OEM tire data from TireRack"
    task populate: :environment do
        #puts ReadData("http://www.tirerack.com/survey/ValidationServlet?autoMake=Acura&autoYearsNeeded=true")
        #puts ReadData("http://www.google.com")

        makes = [#"Acura","Alfa","American Motors","Aston Martin","Audi",
                #"BMW","Bentley",
                #"Buick","Cadillac",
                "Chevrolet","Chrysler","Daewoo","Daihatsu","Datsun",
                "Delorean","Dodge","Eagle","Ferrari","Fiat","Ford","Freightliner","GMC",
                "Geo","Honda","Hummer","Hyundai","Infiniti","Isuzu","Jaguar","Jeep","Kia",
                "Lamborghini","Lancia","Land Rover","Lexus","Lincoln","Lotus","MG","Maserati",
                "Maybach","Mazda","Mercedes-Benz","Mercury","Merkur","Mini","Mitsubishi",
                "Mosler","Nissan","Noble","Oldsmobile","Opel","Panoz","Peugeot","Pininfarina",
                "Plymouth","Pontiac","Porsche","Renault","Ram","Rolls Royce","Roush","Saab",
                "Saleen","Saturn","Scion","Shelby","Shelby Super Car","smart","Spyker","Sterling",
                "Subaru","Suzuki","Tesla","Toyota","Triumph","Volkswagen","Volvo"]

        makes.each do |make|
            # Now let's find what years are available for this maker
            year_url = "http://www.tirerack.com/survey/ValidationServlet?autoMake=#{make}&autoYearsNeeded=true"
            year_url = year_url.gsub(/[' ']/, '%20')
            years = []
            (1..5).each do |i|
                begin
                    year_response = ReadData(year_url)
                    years = Nokogiri::XML(year_response.to_s)
                    break
                rescue Exception => e
                    puts "Error: #{e.to_s} - try again"
                    puts year_url
                end
            end

            years.xpath("//years/year").each do |year|
                # now let's get all the models for this year
                model_url = "http://www.tirerack.com/survey/ValidationServlet?autoYear=#{year.text}&autoMake=#{make}"
                model_url = model_url.gsub(/[' ']/, '%20')
                models = []
                (1..5).each do |i|
                    begin
                        model_response = ReadData(model_url)
                        models = Nokogiri::XML(model_response.to_s)
                        break
                    rescue Exception => e
                        puts "Error: #{e.to_s} - try again"
                        puts model_url
                    end
                end

                models.xpath("//models/model").each do |model|
                    options_url = "http://www.tirerack.com/survey/ValidationServlet?autoYear=#{year.text}&autoMake=#{make}&autoModel=#{model.text}"
                    options_url = options_url.gsub(/[' ']/, '%20')
                    options = []
                    (1..5).each do |i|
                        begin
                            options_response = ReadData(options_url)
                            options = Nokogiri::XML(options_response.to_s)
                            break
                        rescue Exception => e
                            puts "Error: #{e.to_s} - try again"
                        end
                    end

                    options.xpath("//clarifiers/clar").each do |option|
                        # we have everything we need, let's look at the results page for our sizes
                        sizes_url = "http://www.tirerack.com/tires/SelectTireSize.jsp?autoMake=#{make}&autoModel=#{model.text}&autoYear=#{year.text}&autoModClar=#{option.text}"
                        sizes_url = sizes_url.gsub(/[' ']/, '%20')
                        sizes = []
                        (1..5).each do |i|
                            begin
                                sizes_response = ReadData(sizes_url)
                                sizes = Nokogiri::HTML(sizes_response.to_s)
                                break
                            rescue Exception => e
                                puts "Error: #{e.to_s} - try again"
                            end
                        end

                        puts "#{year.text} #{make} #{model.text} #{option.text}"
                        puts "        #{sizes_url}"
                        puts "---------------------------------------"

                        begin
                            all_data = sizes.xpath('//tr[@valign="top"]/td/b')
                            (0..all_data.count - 1).step(2) do |i|
                                description = all_data[i]
                                size = all_data[i + 1]

                                puts "#{description.text} #{size.text}"

                                # now to create the data

                                auto_manu = AutoManufacturer.find_by_name(make)
                                if auto_manu.nil?
                                    puts "Creating a new record for #{make}"
                                    auto_manu = AutoManufacturer.new(:name => make)
                                    auto_manu.save
                                end

                                auto_model = AutoModel.find_by_auto_manufacturer_id_and_name(auto_manu.id, model.text)
                                if auto_model.nil?
                                    puts "Creating a new record for #{make} #{model.text}"
                                    auto_model = AutoModel.new(:auto_manufacturer_id => auto_manu.id, :name => model.text)
                                    auto_model.save
                                end

                                auto_year = AutoYear.find_by_auto_model_id_and_modelyear(auto_model.id, year.text)
                                if auto_year.nil?
                                    puts "Creating a new record for #{year.text} #{make} #{model.text}"
                                    auto_year = AutoYear.new(:auto_model_id => auto_model.id, :modelyear => year.text)
                                    auto_year.save
                                end

                                sizestr = size.text.gsub('-', 'R')
                                tire_size = TireSize.find_by_sizestr(sizestr)
                                if tire_size.nil?
                                    puts "Creating a new record for #{sizestr}"
                                    tire_size = TireSize.new(:sizestr => sizestr)
                                    tire_size.save
                                end

                                auto_option = AutoOption.find_by_auto_year_id_and_name(auto_year.id, option.text)
                                if auto_option.nil?
                                    puts "Creating a new record for #{year.text} #{make} #{model.text} #{option.text}"
                                    auto_option = AutoOption.new(:auto_year_id => auto_year.id, :name => option.text)
                                    auto_option.save
                                end

                                # now set the size for this option
                                auto_option.tire_size_id = tire_size.id
                                auto_option.save
                            end
                        rescue Exception => e
                            # probably no tires for this vehicle
                            puts "ERROR - #{e.to_s}"
                        end
                    end
                end
            end
        end
    end
end
