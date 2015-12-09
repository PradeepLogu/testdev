require 'nokogiri'
require 'open-uri'

def ReadData(url)
    RestClient.get url, :user_agent => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) "
    #open(url, :proxy => "http://54.243.138.45:80", "User-Agent" => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) ").read
end

namespace :CreateDelinteD7 do 
    desc "Create info for Delinte D7"
    task populate: :environment do
        tire_make_str = "Delinte"
        tire_model_str = "D7"

        tire_manu = TireManufacturer.find_or_create_by_name(tire_make_str)
        tire_model_info = TireModelInfo.find_or_create_by_tire_manufacturer_id_and_tire_model_name(tire_manu.id, tire_model_str)

        tire_model_info.photo1_url = "http://www.delintetires.com/wp-content/uploads/2014/02/D7-3-4-wheel1.jpg"
        tire_model_info.description = ""
        tire_model_info.save

        all_tires = [
                        "305/25ZR20!97 !W!XL!10.5-11.0-11.5!9.8!7.8!26.0!660!12.3!313!1609!730!49!340!799!420/A/A",
                        "285/25ZR22!95 !W!XL!10.5          !9.8!7.8!27.6!701!11.6!295!1521!690!49!340!753!420/A/A",
                        "305/25ZR22!103!Y!XL!10.5-11.0-11.5!9.8!7.8!28.0!711!12.3!313!1929!875!49!340!742!420/A/A",
                        "265/30ZR19!93 !W!XL!9.0-9.5-10.0  !9.8!7.8!25.3!643!10.7!271!1433!650!49!340!820!420/A/A",
                        "275/30ZR19!96 !W!XL!9.0-9.5-10.0  !9.8!7.8!25.6!649!10.9!278!1565!710!49!340!813!420/A/A",
                        "225/30ZR20!85 !W!XL!8.0           !9.8!7.8!25.4!644!9.1 !230!1135!515!49!340!819!420/A/A",
                        "245/30ZR20!97 !W!XL!8.0-8.5-9.0   !9.8!7.8!25.8!656!9.8 !248!1609!730!49!340!804!420/A/A",
                        "255/30ZR20!92 !W!XL!8.5-9.0-9.5   !9.8!7.8!26.1!662!10.2!260!1389!630!49!340!797!420/A/A",
                        "275/30ZR20!97 !W!XL!9.0-9.5-10.0  !9.8!7.8!26.5!674!10.9!278!1609!730!49!340!783!420/A/A",
                        "285/30ZR20!99 !W!XL!9.5-10.0-10.5 !9.8!7.8!26.8!680!11.4!290!1709!775!49!340!776!420/A/A",
                        "225/30ZR22!89 !W!XL!8.0           !9.8!7.8!26.6!676!9.1 !230!1279!580!49!340!780!420/A/A",
                        "235/30ZR22!90 !W!XL!8.5           !9.8!7.8!27.6!701!9.5 !241!1323!600!49!340!753!420/A/A",
                        "245/30ZR22!95 !W!XL!8.0-8.5-9.0   !9.8!7.8!27.8!707!9.8 !248!1521!690!49!340!746!420/A/A",
                        "255/30ZR22!95 !Y!XL!8.5-9.0-9.5   !9.8!7.8!28.1!713!10.2!260!1521!690!49!340!740!420/A/A",
                        "265/30ZR22!97 !W!XL!9.0-9.5-10.0  !9.8!7.8!28.3!719!10.7!271!1609!730!49!340!734!420/A/A",
                        "215/35ZR18!84 !W!XL!7.0-7.5-8.5   !9.8!7.8!23.9!607!8.6 !218!1102!500!49!340!869!420/A/A",
                        "255/35ZR18!94 !W!XL!8.5-9.0-10.0  !9.8!7.8!25.0!635!10.2!260!1477!670!49!340!831!420/A/A",
                        "215/35ZR19!85 !W!XL!7.0-7.5-8.5   !9.8!7.8!24.9!633!8.6 !218!1135!515!49!340!833!420/A/A",
                        "225/35ZR19!84 !W!  !7.5-8.0-9.0   !9.8!7.8!25.2!641!9.1 !230!1102!500!44!300!823!420/A/A",
                        "225/35ZR19!88 !W!XL!7.5-8.0-9.0   !9.8!7.8!25.2!641!9.1 !230!1235!560!49!340!823!420/A/A",
                        "235/35ZR19!91 !W!XL!8.0-8.5-9.5   !9.8!7.8!25.5!647!9.5 !241!1356!615!49!340!815!420/A/A",
                        "245/35ZR19!97 !W!XL!8.0-8.5-9.5   !9.8!7.8!25.8!655!9.8 !248!1609!730!49!340!805!420/A/A",
                        "255/35ZR19!96 !W!XL!8.5-9.0-10.0  !9.8!7.8!26.0!661!10.2!260!1565!710!49!340!798!420/A/A",
                        "275/35ZR19!100!W!XL!9.0-9.5-11.0  !9.8!7.8!26.6!675!10.9!278!1764!800!49!340!782!420/A/A",
                        "225/35ZR20!93 !W!XL!7.5-8.0-9.0   !9.8!7.8!26.2!666!9.1 !230!1433!650!49!340!792!420/A/A",
                        "235/35ZR20!92 !W!XL!8.0-8.5-9.5   !9.8!7.8!26.5!672!9.5 !241!1389!630!49!340!785!420/A/A",
                        "245/35ZR20!95 !W!XL!8.0-8.5-9.5   !9.8!7.8!26.8!680!9.8 !248!1521!690!49!340!776!420/A/A",
                        "255/35ZR20!97 !W!XL!8.5-9.0-10.0  !9.8!7.8!27.0!686!10.2!260!1609!730!49!340!769!420/A/A",
                        "275/35ZR20!102!W!XL!9.0-9.5-11.0  !9.8!7.8!27.6!700!10.9!278!1874!850!49!340!754!420/A/A",
                        "205/40ZR17!84 !W!XL!7.0-7.5-8.0   !9.8!7.8!23.5!596!8.3 !212!1102!500!49!340!885!420/A/A",
                        "245/40ZR17!95 !W!XL!8.0-8.5-9.5   !9.8!7.8!24.7!628!9.8 !248!1521!690!49!340!840!420/A/A",
                        "215/40ZR18!89 !W!XL!7.0-7.5-8.5   !9.8!7.8!24.8!629!8.6 !218!1279!580!49!340!839!420/A/A",
                        "225/40ZR18!92 !W!XL!7.5-8.0-9.0   !9.8!7.8!25.1!637!9.1 !230!1389!630!49!340!828!420/A/A",
                        "235/40ZR18!95 !W!XL!8.0-8.5-9.5   !9.8!7.8!25.4!645!9.5 !241!1521!690!49!340!818!420/A/A",
                        "245/40ZR18!97 !W!XL!8.0-8.5-9.5   !9.8!7.8!25.7!653!9.8 !248!1609!730!49!340!808!420/A/A",
                        "255/40ZR18!99 !W!XL!8.5-9.0-10.0  !9.8!7.8!26.0!661!10.2!260!1709!775!49!340!798!420/A/A",
                        "225/40ZR19!93 !W!XL!7.5-8.0-9.0   !9.8!7.8!26.1!663!9.1 !230!1433!650!49!340!796!420/A/A",
                        "245/40ZR19!98 !W!XL!8.0-8.5-9.5   !9.8!7.8!26.7!679!9.8 !248!1653!750!49!340!777!420/A/A",
                        "245/40ZR20!99 !W!XL!8.0-8.5-9.5   !9.8!7.8!27.7!704!9.8 !248!1709!775!49!340!749!420/A/A",
                        "205/45ZR17!88 !W!XL!6.5-7.0-7.5   !9.8!7.8!24.3!616!8.1 !206!1235!560!49!340!856!420/A/A",
                        "215/45ZR17!91 !W!XL!7.0-8.0       !9.8!7.8!24.6!626!8.4 !213!1356!615!49!340!843!420/A/A",
                        "225/45ZR17!94 !W!XL!7.0-7.5-8.5   !9.8!7.8!25.0!634!8.9 !225!1477!670!49!340!832!420/A/A",
                        "235/45ZR17!97 !W!XL!7.5-8.0-9.0   !9.8!7.8!25.4!644!9.3 !236!1609!730!49!340!819!420/A/A",
                        "245/45ZR17!99 !W!XL!7.5-8.0-9.0   !9.8!7.8!25.7!652!9.6 !243!1709!775!49!340!809!420/A/A",
                        "225/45ZR18!95 !W!XL!7.0-7.5-8.5   !9.8!7.8!25.9!659!8.9 !225!1521!690!49!340!801!420/A/A",
                        "245/45ZR18!100!Y!XL!7.5-8.0-9.0   !9.8!7.8!26.7!677!9.6 !243!1764!800!49!340!779!420/A/A",
                        "225/45ZR19!96 !W!XL!7.0-7.5-8.5   !9.8!7.8!27.0!685!8.9 !225!1565!710!49!340!770!420/A/A",
                        "245/45ZR19!98 !Y!  !7.5-8.0-9.0   !9.8!7.8!27.7!703!9.6 !243!1653!750!44!300!750!420/A/A",
                        "255/45ZR20!105!W!XL!8.0-8.5-9.5   !9.8!7.8!29.1!738!10.0!255!2039!925!49!340!715!420/A/A",
                        "205/50ZR17!93 !W!XL!5.5-6.5-7.5   !9.8!7.8!25.1!638!8.4 !214!1433!650!49!340!827!420/A/A",
                        "225/50ZR17!98 !W!XL!6.0-7.0-8.0   !9.8!7.8!25.9!658!9.2 !233!1653!750!49!340!802!420/A/A",
                        "235/50ZR18!101!W!XL!6.5-7.5-8.5   !9.8!7.8!27.3!693!9.6 !245!1819!825!49!340!761!420/A/A",
                        "205/55ZR16!91 !W!  !5.5-6.5-7.5   !9.8!7.8!24.9!632!8.4 !214!1356!615!44!300!835!420/A/A",
                        "215/55ZR17!94 !W!  !6.0-7.0-7.5   !9.8!7.8!26.3!668!8.9 !226!1477!670!44!300!790!420/A/A",
                        "225/55ZR17!101!W!XL!6.0-7.0-8.0   !9.8!7.8!26.8!680!9.2 !233!1819!825!49!340!776!420/A/A",
                        "235/55ZR17!103!W!XL!6.5-7.5-8.5   !9.8!7.8!27.2!690!9.6 !245!1929!875!49!340!765!420/A/A",
                        "235/55R18 !104!V!XL!6.5-7.5-8.5   !9.8!7.8!28.1!715!9.6 !245!1984!900!49!340!738!420/A/A",
                        "215/60R16 !99 !H!XL!6.0-6.5-7.5   !10.5!8.3!26.1!664!8.7!221!1709!775!49!340!794!420/A/A",
                        "225/60R16 !98 !H!  !6.0-6.5-8.0   !10.5!8.3!26.6!676!9.0!228!1653!750!44!300!780!420/A/A"            
                    ]
        all_tires.each do |tire|
            ar = tire.split("!")

            sizestr = ar[0].gsub(/ZR/, 'R').strip()
            load_index = ar[1].strip()
            speed_rating = ar[2].strip()
            tread_depth = ar[5].strip()
            utqg = ar[16].split("/")

            utqg_treadwear = utqg[0]
            utqg_temp = utqg[1]
            utqg_traction = utqg[2]

            tire_size = TireSize.find_by_sizestr(sizestr)
            if tire_size.nil?
                puts "Not found: #{sizestr}"

                tire_size =  TireSize.new(:sizestr => sizestr)
                tire_size.save
            else
                puts "Found: #{sizestr}"
            end

            tire_model = TireModel.find_or_create_by_tire_manufacturer_id_and_tire_size_id_and_name(tire_manu.id, tire_size.id, tire_model_str)

            tire_model.tire_model_info_id = tire_model_info.id
            tire_model.load_index = load_index
            tire_model.speed_rating = speed_rating
            #tire_model.sidewall = sidewall
            #tire_model.rim_width = rim_width
            tire_model.tread_depth = tread_depth
            tire_model.utqg_temp = utqg_temp
            tire_model.utqg_traction = utqg_traction
            tire_model.utqg_treadwear = utqg_treadwear

            puts "Load Index: #{load_index}"
            puts "Speed Rating: #{speed_rating}"
            puts "Temp: #{utqg_temp}"
            puts "Traction: #{utqg_traction}"
            puts "Treadwear: #{utqg_treadwear}"
            puts "================================================="
            tire_model.save
        end
    end
end

namespace :ScrapePerformancePlusModelInfo do
    desc "Create tire manufacturers data from Performance Plus site"
    task populate: :environment do
        tire_make = "Delinte"
        tire_model = "Thunder D7"

        model_url = "http://www.performanceplustire.com/tires-for-sale/#{tire_make}-tires/#{tire_model}".downcase()
        model_url = "http://www.performanceplustire.com/tires-for-sale/#{tire_make}-tires/thunder-d7-tire".downcase()

        model_url = URI::encode(model_url)
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

            html_data.xpath("//div[@class='productDetailRow']").each do |tire_size|
                manu = TireManufacturer.find_or_create_by_name(tire_make)

                specs = tire_size.xpath(".//td[@class='productDetailData']")[1]
                s1 = specs.xpath(".//strong")[0].text().strip()
                s2 = specs.xpath(".//strong")[1].text().strip()
                s3 = specs.xpath(".//strong")[2].text().strip()
                s4 = specs.xpath(".//strong")[3].text().strip()
                s5 = specs.xpath(".//strong")[4].text().strip()
                s6 = specs.xpath(".//strong")[5].text().strip()
                s7 = specs.xpath(".//strong")[6].text().strip()

                if s2 == "BLACK"
                    s2 = "BW"
                end

                sizestr = tire_size.xpath(".//td[@class='productDetailData']")[0].text().strip().split(' ')[0].gsub(/ZR/, 'R').gsub(/HR/, 'R').gsub(/VR/, 'R').gsub(/P/, '')
                load = tire_size.xpath(".//td[@class='productDetailData']")[0].text().strip().split(' ')[1]
                if !load || load == ""
                    load_index = ''
                    speed_rating = ''
                else
                    load_index = load.scan(/\d/).join
                    speed_rating = load.scan(/\D/).join
                end
                unless s7 == '-' || s7 == '' || s7 == 'N/A' || s7 == "--"
                    utArray = s7.split('-')
                    utqg_treadwear = utArray[0]
                    utqg_traction = utArray[1]
                    utqg_temp = utArray[2]
                else
                    utqg_treadwear = 
                    utqg_traction = ''
                    utqg_temp = ''
                end

                speed_rating = s1
                sidewall = s2
                rim_width = s6

                puts "Size: #{sizestr}"
                puts "Load: #{load_index}"
                puts "Speed: #{speed_rating}"
                puts "Sidewall: #{sidewall}"
                puts "Rim: #{rim_width}"
                puts "Treadwear: #{utqg_treadwear}"
                puts "Traction: #{utqg_traction}"
                puts "Temp: #{utqg_temp}"

                ts = TireSize.find_by_sizestr(sizestr)
                if !ts 
                    puts "Unable to find size #{sizestr}"
                else
                    tm = TireModel.find_or_create_by_tire_manufacturer_id_and_tire_size_id_and_name(manu.id, ts.id, tire_model)
                    #tm = TireModel.new
                    tm.load_index = load_index
                    tm.speed_rating = speed_rating
                    tm.sidewall = sidewall
                    tm.rim_width = rim_width
                    tm.utqg_temp = utqg_temp
                    tm.utqg_traction = utqg_traction
                    tm.utqg_treadwear = utqg_treadwear
                    tm.save
                end
            end
        else
            puts "Unable to read URL: #{model_url}.  Please check this URL to see if make and model were entered correctly."
        end
    end
end