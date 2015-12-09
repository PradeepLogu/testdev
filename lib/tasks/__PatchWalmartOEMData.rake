require 'nokogiri'
require 'open-uri'

def ReadData(url)
    RestClient.get url, :user_agent => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) "
    #open(url, :proxy => "http://54.243.138.45:80", "User-Agent" => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) ").read
end

namespace :PatchWalmart do
    desc "Patch OEM tire data from Walmart"
    task populate: :environment do
        years = [
                 "2012", "2011", "2010", "2009", "2008", "2007","2006", 
                 "2005", "2004", "2003", "2002", "2001", "2000",
                 "1999", "1998", "1997", "1996", 
                 "1995", "1994", "1993",
                 "1992", "1991", "1990", "1989", "1988", "1987", "1986"]

        makes = ["ACURA","ALFA ROMEO","AMC/RENAULT","AMERICAN MOTORS",
                "ASTON MARTIN","AUDI","AVANTI","BENTLEY","BERTONE","BMW",
                "BUICK","CADILLAC","CHEVROLET","CHRYSLER","DAEWOO",
                "DAIHATSU","DODGE","EAGLE","FERRARI","FIAT","FORD",
                "FREIGHTLINER","GEO","GMC","HONDA","HUMMER","HYUNDAI",
                "INFINITI","ISUZU","JAGUAR","JEEP","KIA","LAMBORGHINI",
                "LAND ROVER","LEXUS","LINCOLN","LOTUS","MASERATI",
                "MAYBACH","MAZDA","MERCEDES-BENZ","MERCURY","MINI",
                "MITSUBISHI","NISSAN","OLDSMOBILE","PANOZ","PEUGEOT",
                "PLYMOUTH","PONTIAC","PORSCHE","RAM","RENAULT","ROLLS ROYCE",
                "SAAB","SATURN","SCION","SMART","STERLING","SUBARU",
                "SUZUKI","TOYOTA","VOLKSWAGEN","VOLVO","YUGO"]

        years.each do |year|
            makes.each do |make|
            if make == 'SATURN'
                # post to modelByYearAndMakeAction.do page
                # to get a list of models for that year/manu
                models_url = "http://www.walmart.com/catalog/modelByYearAndMakeAction.do?year=#{year}&make=#{make}"
                #models_url = models_url.gsub(/[' ']/, '%20')
                models_url = URI::encode(models_url)

                # try up to 5 times in case we have some sort
                # of network burp
                models = []
                (1..5).each do |i|
                    begin
                        #puts models_url
                        models_response = ReadData(models_url)
                        if models_response != ''
                            models = JSON.parse(models_response)
                        else
                            puts "Empty response #{models_url}"
                        end
                        break
                    rescue Exception => e
                        puts "Error: #{e.to_s} - try again"
                        puts models_url
                    end
                end

                # do we have models?
                if models.count > 0
                    # we have to split this up to get an option.
                    # this is a bit of a clusterf*** because Walmart doesn't
                    # have the concept of "options" but we require it.
                    # some of these will be whackadoodle and need to be cleaned
                    # up later.
                    models.each do |full_model|
                        ar = full_model.split(' ')
                        model = ar[0]
                        option = ar[1..99].join(' ')

                        # now hit the Walmart website to find the size(s)
                        size_url = "http://www.walmart.com/catalog/tiresAction.do?cat=91085&Flag=TiresV&year=#{year}&make=#{make}&model=#{full_model}"
                        size_url = URI::encode(size_url)
                        size_response = ''
                        (1..5).each do |i|
                            begin
                                size_response = ReadData(size_url)
                                break
                            rescue Exception => e 
                                puts "Error: #{e.to_s} - try again"
                            end
                        end
                        if size_response != '' # there was no error
                            html_sizes = Nokogiri::HTML(size_response.to_s)
                            html_sizes.xpath("//span[@class='Body3XL']").each do |size|
                                sizes = size.text.split(' ')
                                if sizes[0] != '/'
                                    puts "#{year} - #{make} - #{model} - #{option} - *#{sizes[0]}*"

                                    # now create data as needed.
                                    begin
                                        auto_manu = AutoManufacturer.find_or_create_by_name(make.titleize)
                                        auto_model = AutoModel.find_or_create_by_auto_manufacturer_id_and_name(auto_manu.id, model.titleize)
                                        auto_year = AutoYear.find_or_create_by_modelyear_and_auto_model_id(year, auto_model.id)
                                        tire_size = TireSize.find_or_create_by_sizestr(sizes[0])
                                        
                                        if !AutoOption.find_by_auto_year_id_and_name(auto_year.id, option)
                                            puts "  Record not found - creating"
                                        end

                                        auto_option = AutoOption.find_or_create_by_auto_year_id_and_name(auto_year.id, option)

                                        auto_option.tire_size_id = tire_size.id
                                        auto_option.save
                                    rescue Exception => e
                                        puts "We had an error creating data - #{e.to_s} - ignoring for now..."
                                    end
                                    break
                                end
                            end
                        end
                    end
                else
                    puts "No models found."
                end
            end
            end
        end
    end
end
