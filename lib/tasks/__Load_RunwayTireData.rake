require 'nokogiri'
require 'open-uri'

def ReadData(url)
    #open(url, :proxy => "http://54.243.138.45:80", "User-Agent" => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) ").read
end

namespace :ScrapeRunwayTire do
    desc "Get OEM tire data from Runway-Tire.com"
    task populate: :environment do
        manu = TireManufacturer.find_or_create_by_name("Runway")

        TireSize.find_or_create_by_sizestr("145/80R13")
        TireSize.find_or_create_by_sizestr("155/65R13")
        TireSize.find_or_create_by_sizestr("175/65R13")
        TireSize.find_or_create_by_sizestr("155/65R14")
        TireSize.find_or_create_by_sizestr("155/70R13")

        model_pages = [{"url" => "http://www.runway-tires.com/runway/us/tiredetail.asp?mastertireid=ChinaPattern000378&flag=3",
                        "category" => "Ultra High Performance Summer",
                        "name" => "Enduro 916+"},
                        {"url" => "http://www.runway-tires.com/runway/us/tiredetail.asp?mastertireid=ChinaPattern000379&flag=3",
                        "category" => "Performance All-Season",
                        "name" => "Enduro 816"},
                        {"url" => "http://www.runway-tires.com/runway/us/tiredetail.asp?mastertireid=ChinaPattern000057&flag=3",
                        "category" => "Performance All-Season",
                        "name" => "Enduro 716"},
                        {"url" => "http://www.runway-tires.com/runway/us/tiredetail.asp?mastertireid=ChinaPattern000052&flag=3",
                        "category" => "Standard Touring All-Season",
                        "name" => "Enduro 506"},
                        {"url" => "http://www.runway-tires.com/runway/us/tiredetail.asp?mastertireid=ChinaPattern000056&flag=3",
                        "category" => "Standard Touring All-Season",
                        "name" => "Enduro 556"},
                        {"url" => "http://www.runway-tires.com/runway/us/tiredetail.asp?mastertireid=ChinaPattern000095&flag=3",
                        "category" => "Standard Touring All-Season",
                        "name" => "Enduro 606"},
                        {"url" => "http://www.runway-tires.com/runway/us/tiredetail.asp?mastertireid=ChinaPattern000053&flag=3",
                        "category" => "Standard Touring All-Season",
                        "name" => "Enduro 656"},
                        {"url" => "http://www.runway-tires.com/runway/us/tiredetail.asp?mastertireid=ChinaPattern000423&flag=3",
                        "category" => "Passenger All-Season",
                        "name" => "Enduro 726"},
                        {"url" => "http://www.runway-tires.com/runway/us/tiredetail.asp?mastertireid=ChinaPattern000051&flag=3",
                        "category" => "Passenger All-Season",
                        "name" => "Enduro 706"},
                        {"url" => "http://www.runway-tires.com/runway/us/tiredetail.asp?mastertireid=ChinaPattern000054&flag=3",
                        "category" => "Passenger All-Season",
                        "name" => "Enduro 75"},
                        {"url" => "http://www.runway-tires.com/runway/us/tiredetail.asp?mastertireid=ChinaPattern000337&flag=3",
                        "category" => "Performance Winter",
                        "name" => "RWT-1"},
                        {"url" => "http://www.runway-tires.com/runway/us/tiredetail.asp?mastertireid=ChinaPattern000092&flag=3",
                        "category" => "Street/Sport Truck All-Season",
                        "name" => "Enduro H/T"},
                        {"url" => "http://www.runway-tires.com/runway/us/tiredetail.asp?mastertireid=ChinaPattern000568&flag=3",
                        "category" => "Street/Sport Truck All-Season",
                        "name" => "Enduro H/T2"},
                        {"url" => "http://www.runway-tires.com/runway/us/tiredetail.asp?mastertireid=ChinaPattern000094&flag=3",
                        "category" => "On-/Off-Road All-Terrain",
                        "name" => "Enduro A/T"},
                        {"url" => "http://www.runway-tires.com/runway/us/tiredetail.asp?mastertireid=ChinaPattern000206&flag=3",
                        "category" => "On-/Off-Road All-Terrain",
                        "name" => "Enduro M/T"}]
        model_pages.each do |model_hash|
            puts "model = #{model_hash['name']}"
            puts "category = #{model_hash['category']}"
            puts "url = #{model_hash['url']}"

            model_response = ReadData(model_hash['url'])
            html_model = Nokogiri::HTML(model_response.to_s)

            html_model.xpath("//tr[@bgcolor='#F0F0F0' or @bgcolor='#FFFFFF']").each do |size|
                cells = size.xpath(".//td")
                puts "-------------------------"
                arSize = cells[1].text.strip().scan(/\d{2,}/)
                if arSize.size == 3
                    sizestr = "#{arSize[0]}/#{arSize[1]}R#{arSize[2]}"
                    ts = TireSize.find_by_sizestr(sizestr)
                    if !ts 
                        puts "**** INVALID SIZE  #{sizestr} ****"
                    else
                        tc = TireCategory.find_by_category_name(model_hash['category'])
                        tm = TireModel.find_or_create_by_tire_manufacturer_id_and_tire_size_id_and_name(manu.id, ts.id, model_hash['name'])
                        tm.load_index = cells[2].text.strip()
                        tm.speed_rating = cells[3].text.strip()
                        tm.tire_category_id = tc.id

                        if cells.size == 13
                            unless cells[4].text.strip() == '-'
                                utArray = cells[4].text.strip().split(' ')
                                tm.utqg_treadwear = utArray[0]
                                tm.utqg_traction = utArray[1]
                                tm.utqg_temp = utArray[2]
                            end
                            tm.tread_depth = cells[10].text.strip()
                            tm.sidewall = cells[12].text.strip()
                        elsif cells.size == 12
                            tm.tread_depth = cells[9].text.strip()
                            tm.sidewall = cells[11].text.strip()
                        else
                            puts "********* WTF"
                        end

                        tm.save
                    end
                else
                    puts "**** INVALID SIZE  #{cells[1].text.strip()} ****"
                end
            end
        end
    end
end
