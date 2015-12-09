require 'nokogiri'
require 'open-uri'

def ReadData(url)
    RestClient.get url, :user_agent => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) "
    #open(url, :proxy => "http://54.243.138.45:80", "User-Agent" => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) ").read
end

namespace :ScrapeVanderbilt do
    desc "Create tire manufacturers data from Vanderbilt"
    task populate: :environment do
        tire_make = "Vanderbilt"
        model_name = "Turbo Tech Radial GT"

        manu = TireManufacturer.find_or_create_by_name(tire_make)

        model_url = "http://www.vanderbilttires.com/tires/Detail.aspx?lineid=261&application=Performance"
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
            model_data = Nokogiri::HTML(model_response.to_s)
            model_data.xpath("//tr").each do |tire_size|
                all_data = Nokogiri::HTML(tire_size.to_s).xpath(".//td")

                if all_data && all_data.size > 7
                    sizestr = all_data[1].text().strip().gsub(/P/, '').gsub(/Z/, '')
                    service = all_data[2].text().strip()

                    if service == '-' || service == ''
                        load_index = speed_rating = ""
                    else
                        load_index = service.scan(/\d{2,}/)[0]
                        speed_rating = service.scan(/\D/)[0]
                    end

                    utqg = all_data[4].text().strip()
                    utArray = utqg.split(' ')
                    utqg_treadwear = utArray[0]
                    utqg_traction = utArray[1]
                    utqg_temp = utArray[2]

                    tread_depth = all_data[5].text().strip()
                    sidewall = all_data[6].text().strip()
                    rim_width = all_data[7].text().strip()

                    puts "SIZE: #{sizestr}"
                    puts "LI: #{load_index}"
                    puts "SPEED: #{speed_rating}"
                    puts "DEPTH: #{tread_depth}"
                    puts "TREADWEAR: #{utqg_treadwear}"
                    puts "TRACTION: #{utqg_traction}"
                    puts "TEMP: #{utqg_temp}"
                    puts "RIM: #{rim_width}"
                    puts "SIDEWALL: #{sidewall}"
                    puts "***************************"

                    ts = TireSize.find_by_sizestr(sizestr)
                    if !ts 
                        puts "BAD SIZE: #{sizestr}"
                    else
                        tm = TireModel.find_or_create_by_tire_manufacturer_id_and_tire_size_id_and_name(manu.id, ts.id, model_name)
                        #tm = TireModel.new
                        tm.load_index = load_index
                        tm.speed_rating = speed_rating
                        tm.tread_depth = tread_depth
                        tm.utqg_treadwear = utqg_treadwear
                        tm.utqg_temp = utqg_temp
                        tm.utqg_traction = utqg_traction
                        tm.rim_width = rim_width
                        tm.sidewall = sidewall
                        tm.save
                    end
                end
            end
        end
    end
end


namespace :ScrapeSigma do
    desc "Create tire manufacturers data from Sigma"
    task populate: :environment do
        tire_make = "Sigma"
        model_name = "Wild Spirit Sport H/T"

        TireSize.find_or_create_by_sizestr("245/75R16")
        TireSize.find_or_create_by_sizestr("265/75R16")
        TireSize.find_or_create_by_sizestr("245/70R17")

        manu = TireManufacturer.find_or_create_by_name(tire_make)

        model_url = "http://www.sigmatires.com/tires/Detail.aspx?lineid=248&application=SUV-LT"
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
            model_data = Nokogiri::HTML(model_response.to_s)
            model_data.xpath("//tr").each do |tire_size|
                all_data = Nokogiri::HTML(tire_size.to_s).xpath(".//td")

                if all_data && all_data.size > 7
                    sizestr = all_data[1].text().strip().gsub(/P/, '').gsub(/Z/, '').gsub(/LT/, '')
                    service = all_data[2].text().strip()

                    if service == '-' || service == ''
                        load_index = speed_rating = ""
                    else
                        load_index = service.scan(/\d{2,}/)[0]
                        speed_rating = service.scan(/\D/)[0]
                    end

                    speed_rating = "" if speed_rating == "/"

                    utqg = all_data[4].text().strip()
                    utArray = utqg.split(' ') if utqg.include?(' ')
                    utArray = utqg.split('-') if utqg.include?('-')
                    if utArray && utArray.size >= 3
                        utqg_treadwear = utArray[0]
                        utqg_traction = utArray[1]
                        utqg_temp = utArray[2]
                    end

                    tread_depth = all_data[5].text().strip()
                    sidewall = all_data[6].text().strip()
                    rim_width = all_data[7].text().strip()

                    puts "SIZE: #{sizestr}"
                    puts "LI: #{load_index}"
                    puts "SPEED: #{speed_rating}"
                    puts "DEPTH: #{tread_depth}"
                    puts "TREADWEAR: #{utqg_treadwear}"
                    puts "TRACTION: #{utqg_traction}"
                    puts "TEMP: #{utqg_temp}"
                    puts "RIM: #{rim_width}"
                    puts "SIDEWALL: #{sidewall}"
                    puts "***************************"

                    ts = TireSize.find_by_sizestr(sizestr)
                    if !ts 
                        puts "BAD SIZE: #{sizestr}"
                    else
                        tm = TireModel.find_or_create_by_tire_manufacturer_id_and_tire_size_id_and_name(manu.id, ts.id, model_name)
                        #tm = TireModel.new
                        tm.load_index = load_index
                        tm.speed_rating = speed_rating
                        tm.tread_depth = tread_depth
                        tm.utqg_treadwear = utqg_treadwear
                        tm.utqg_temp = utqg_temp
                        tm.utqg_traction = utqg_traction
                        tm.rim_width = rim_width
                        tm.sidewall = sidewall
                        tm.save
                    end
                end
            end
        end
    end
end



namespace :ScrapeMultiMile do
    desc "Create tire manufacturers data from MultiMile"
    task populate: :environment do
        tire_make = "MultiMile"
        model_name = "Wild Spirit Sport H/T"

        TireSize.find_or_create_by_sizestr("245/75R16")
        TireSize.find_or_create_by_sizestr("265/75R16")
        TireSize.find_or_create_by_sizestr("245/70R17")

        manu = TireManufacturer.find_or_create_by_name(tire_make)

        model_url = "http://www.multimiletires.com/tires/Detail.aspx?lineid=248&application=SUV-LT"
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
            model_data = Nokogiri::HTML(model_response.to_s)
            model_data.xpath("//tr").each do |tire_size|
                all_data = Nokogiri::HTML(tire_size.to_s).xpath(".//td")

                if all_data && all_data.size > 7
                    sizestr = all_data[1].text().strip().gsub(/P/, '').gsub(/Z/, '').gsub(/LT/, '')
                    service = all_data[2].text().strip()

                    if service == '-' || service == ''
                        load_index = speed_rating = ""
                    else
                        load_index = service.scan(/\d{2,}/)[0]
                        speed_rating = service.scan(/\D/)[0]
                    end

                    speed_rating = "" if speed_rating == "/"

                    utqg = all_data[4].text().strip()
                    utArray = utqg.split(' ') if utqg.include?(' ')
                    utArray = utqg.split('-') if utqg.include?('-')
                    if utArray && utArray.size >= 3
                        utqg_treadwear = utArray[0]
                        utqg_traction = utArray[1]
                        utqg_temp = utArray[2]
                    end

                    tread_depth = all_data[5].text().strip()
                    sidewall = all_data[6].text().strip()
                    rim_width = all_data[7].text().strip()

                    puts "SIZE: #{sizestr}"
                    puts "LI: #{load_index}"
                    puts "SPEED: #{speed_rating}"
                    puts "DEPTH: #{tread_depth}"
                    puts "TREADWEAR: #{utqg_treadwear}"
                    puts "TRACTION: #{utqg_traction}"
                    puts "TEMP: #{utqg_temp}"
                    puts "RIM: #{rim_width}"
                    puts "SIDEWALL: #{sidewall}"
                    puts "***************************"

                    ts = TireSize.find_by_sizestr(sizestr)
                    if !ts 
                        puts "BAD SIZE: #{sizestr}"
                    else
                        tm = TireModel.find_or_create_by_tire_manufacturer_id_and_tire_size_id_and_name(manu.id, ts.id, model_name)
                        #tm = TireModel.new
                        tm.load_index = load_index
                        tm.speed_rating = speed_rating
                        tm.tread_depth = tread_depth
                        tm.utqg_treadwear = utqg_treadwear
                        tm.utqg_temp = utqg_temp
                        tm.utqg_traction = utqg_traction
                        tm.rim_width = rim_width
                        tm.sidewall = sidewall
                        tm.save
                    end
                end
            end
        end
    end
end



namespace :ScrapeCordovan do
    desc "Create tire manufacturers data from Cordovan"
    task populate: :environment do
        tire_make = "Cordovan"
        model_name = "Wild Spirit Sport H/T"

        TireSize.find_or_create_by_sizestr("245/75R16")
        TireSize.find_or_create_by_sizestr("265/75R16")
        TireSize.find_or_create_by_sizestr("245/70R17")

        manu = TireManufacturer.find_or_create_by_name(tire_make)

        model_url = "http://www.cordovantires.com/tires/Detail.aspx?lineid=248&application=SUV-LT"
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
            model_data = Nokogiri::HTML(model_response.to_s)
            model_data.xpath("//tr").each do |tire_size|
                all_data = Nokogiri::HTML(tire_size.to_s).xpath(".//td")

                if all_data && all_data.size > 7
                    sizestr = all_data[1].text().strip().gsub(/P/, '').gsub(/Z/, '').gsub(/LT/, '')
                    service = all_data[2].text().strip()

                    if service == '-' || service == ''
                        load_index = speed_rating = ""
                    else
                        load_index = service.scan(/\d{2,}/)[0]
                        speed_rating = service.scan(/\D/)[0]
                    end

                    speed_rating = "" if speed_rating == "/"

                    utqg = all_data[4].text().strip()
                    utArray = utqg.split(' ') if utqg.include?(' ')
                    utArray = utqg.split('-') if utqg.include?('-')
                    if utArray && utArray.size >= 3
                        utqg_treadwear = utArray[0]
                        utqg_traction = utArray[1]
                        utqg_temp = utArray[2]
                    end

                    tread_depth = all_data[5].text().strip()
                    sidewall = all_data[6].text().strip()
                    rim_width = all_data[7].text().strip()

                    puts "SIZE: #{sizestr}"
                    puts "LI: #{load_index}"
                    puts "SPEED: #{speed_rating}"
                    puts "DEPTH: #{tread_depth}"
                    puts "TREADWEAR: #{utqg_treadwear}"
                    puts "TRACTION: #{utqg_traction}"
                    puts "TEMP: #{utqg_temp}"
                    puts "RIM: #{rim_width}"
                    puts "SIDEWALL: #{sidewall}"
                    puts "***************************"

                    ts = TireSize.find_by_sizestr(sizestr)
                    if !ts 
                        puts "BAD SIZE: #{sizestr}"
                    else
                        tm = TireModel.find_or_create_by_tire_manufacturer_id_and_tire_size_id_and_name(manu.id, ts.id, model_name)
                        #tm = TireModel.new
                        tm.load_index = load_index
                        tm.speed_rating = speed_rating
                        tm.tread_depth = tread_depth
                        tm.utqg_treadwear = utqg_treadwear
                        tm.utqg_temp = utqg_temp
                        tm.utqg_traction = utqg_traction
                        tm.rim_width = rim_width
                        tm.sidewall = sidewall
                        tm.save
                    end
                end
            end
        end
    end
end

