require 'nokogiri'
require 'open-uri'

def ReadData(url)
    RestClient.get url#, :user_agent => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) "
    #open(url, :proxy => "http://54.243.138.45:80", "User-Agent" => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) ").read
end

def translate_mfr_name(name)
    case name.strip()
    when 'Multi-Mile'
        "MultiMile"
    when 'BFGoodrich'
        "BF Goodrich"
    else
        name.strip()
    end
end

def translate_model_name(name)
    case name.strip()
    when 'P6 Four Seasons'
        "P6 Four Seasons Plus"
    when 'Weather Wise II'
        "Weatherwise II"
    when 'Touring Contact AS'
        "ContiTouringContact AS"
    when 'AS 530'
        "AS530"
    when 'Turanza EL400'
        "Turanza EL400-02"
    when 'LTX M/S'
        "LTX M/S2"
    when 'Affinity'
        "Affinity (S4 Tread Pattern)"
    when 'P Zero Rosso NO'
        "P Zero Rosso"
    when '4X4 Contact'
        "Conti4x4Contact"
    when 'Insignia SE'
        "Insignia SE200"
    when 'Assurance'
        "Assurance ComforTred Touring"
    when 'AVID S34'
        "AVID S34D"
    when 'Wrangler RT/S'
        "Wrangler RT/S (P)"
    when 'Turanza Serenity'
        "Turanza w/Serenity Technology"
    when 'ContiproContact'
        "ContiProContact"
    when 'Eagle F1'
        "Eagle F1 Asymmetric"
    when 'P6 Four Seasons Plus'
        "P6 Four Seasons"
    when 'Radial RA07'
        "RA07 Radial"
    when 'ContisportContact 3'
        "ContiSportContact 3"
    when '4x4 Contact'
        "Conti4x4Contact"
    when 'Optimo H431'
        "H431 Optimo"
    when 'Pilot HXMXM4'
        "Pilot MXM4"
    when 'Scorpion Zero Asimetrico'
        "Scorpion Zero Asimmetrico"
    when 'ZE-502'
        "Ziex ZE-502"
    when 'Potenza RE050A'
        "Potenza RE050"
    when 'Rugged Trail'
        "Rugged Trail T/A"
    when 'Primacy MxM4'
        "Primacy MXM4"
    when 'Pilot HxMxM4'
        "Pilot MXM4"
    when 'Dueler H/T'
        "Dueler H/T 684"
    when '4X4 Diamaris'
        "4x4 Diamaris"
    when 'ContirpContact'
        "ContiProContact"
    when 'Eagle LS2'
        "Eagle LS-2"
    when 'Sp Sport 01 DSST RunFlat'
        "SP Sport 01 DSST ROF"
    when 'Sp Sport MAXX GT'
        "SP Sport Maxx GT"
    when 'Sp Sport Maxx'
        "SP Sport Maxx"
    else
        name.strip()
    end
end

namespace :ScrapeTireKingz do
    manu_list = "StarFire|Uniroyal|Dakota|Nitto|Arizonian|BF Goodrich|BFGoodrich|Bridgestone|Continental|Dunlop|Falken|Firestone|Goodyear|Hankook|Kumho|Michelin|Multi-Mile|Nexen|Pirelli|Sumitomo|Toyo|Yokohama|Savero|Winston|Continetnal"
    desc "Scrape TireKingzAtl.com for data"
    task populate: :environment do
        start_time = Time.now

        tire_stores_hash = {}
        records_added_hash = {}
        records_deleted_hash = {}

        tire_store = TireStore.find_by_name_and_city('Tire Kingz of Atlanta', 'Atlanta')
        if !tire_store
            puts "**** CREATING TIRESTORE RECORD"
            tire_store = TireStore.new
            tire_store.name = 'Tire Kingz of Atlanta'
            tire_store.address1 = '1366 Memorial Drive'
            tire_store.city = 'Atlanta'
            tire_store.state = 'GA'
            tire_store.zipcode = '30317'
            tire_store.phone = '4043714018'
            tire_store.contact_email = 'kirick@treadhunter.com'
            tire_store.save
            tire_store.errors.each do |e|
                puts e.to_s 
            end
        end
        tire_stores_hash["TK-"] = tire_store
        records_added_hash["TK-"] = 0
        records_deleted_hash["TK-"] = 0

        tire_store = TireStore.find_by_name_and_city('Tire Kingz of Decatur', 'Decatur')
        if !tire_store
            puts "**** CREATING TIRESTORE RECORD"
            tire_store = TireStore.new
            tire_store.name = 'Tire Kingz of Decatur'
            tire_store.address1 = '5449 Covington Highway'
            tire_store.city = 'Decatur'
            tire_store.state = 'GA'
            tire_store.zipcode = '30035'
            tire_store.phone = '7703230051'
            tire_store.contact_email = 'kirick@treadhunter.com'
            tire_store.save
            tire_store.errors.each do |e|
                puts e.to_s 
            end
        end
        tire_stores_hash["DEC"] = tire_store
        records_added_hash["DEC"] = 0
        records_deleted_hash["DEC"] = 0

        tire_store = TireStore.find_by_name_and_city('Tire Kingz of Lithia Springs', 'Lithia Springs')
        if !tire_store
            puts "**** CREATING TIRESTORE RECORD"
            tire_store = TireStore.new
            tire_store.name = 'Tire Kingz of Lithia Springs'
            tire_store.address1 = '3664 Veterans Memorial Highway'
            tire_store.city = 'Lithia Springs'
            tire_store.state = 'GA'
            tire_store.zipcode = '30122'
            tire_store.phone = '7707390101'
            tire_store.contact_email = 'kirick@treadhunter.com'
            tire_store.save
            tire_store.errors.each do |e|
                puts e.to_s 
            end
        end
        tire_stores_hash["LS-"] = tire_store
        records_added_hash["LS-"] = 0
        records_deleted_hash["LS-"] = 0


        tk_url = "http://www.tirekingzatl.com/Used-Tires-s/1818.htm?searching=Y&sort=13&cat=1818&show=9999&page=1"

        tk_response = ''

        tot_processed = 0

        (1..5).each do |i|
            begin
                tk_response = ReadData(tk_url)
                break
            rescue Exception => e 
                puts "Error processing #{tk_url}: #{e.to_s} - try again"
            end
        end
        
        valid_count = 0
        nbsp = Nokogiri::HTML("&nbsp;").text
        confidence = FuzzyStringMatch::JaroWinkler.create(:pure)

        if tk_response != '' # there was no error
            html_data = Nokogiri::HTML(tk_response.to_s)

            html_data.xpath("//a[@class='productnamecolor colors_productname']").each do |tk_listing_xpath|
                tot_processed += 1
                if tot_processed > 9999
                    break
                end

                #puts "#{tk_listing_xpath}"
                tk_listing_url = tk_listing_xpath.attribute('href').text().strip()

                if tk_listing_url.to_s != "http://www.tirekingzatl.com/265-35-18-Pirelli-Pzero-Nero-p/dec-748.htm" &&
                    tk_listing_url.to_s != "http://www.tirekingzatl.com/245-60-18-Nitto-NT850-Premium-Used-Tires-p/dec-560.htm" &&
                    tk_listing_url.to_s != "http://www.tirekingzatl.com/285-75-16-StarFire-SF-510-LT-Used-Tires-p/dec-678.htm" &&
                    tk_listing_url.to_s != "http://www.tirekingzatl.com/225-75-15-Goodyear-Marathon-Radial-Used-Tires-p/dec-737.htm" &&
                    tk_listing_url.to_s != "http://www.tirekingzatl.com/255-65-16-Michelin-Cross-Terrain-SUV-Used-Tires-p/dec-505.htm" &&
                    tk_listing_url.to_s != "http://www.tirekingzatl.com/265-75-16-Winner-A-T-Used-Tires-p/dec-711.htm" &&
                    tk_listing_url.to_s != "http://www.tirekingzatl.com/225-65-17-Yokohama-YK520-Used-Tires-p/dec-538.htm" &&
                    tk_listing_url.to_s != "http://www.tirekingzatl.com/245-55-17-Michelin-Primacy-MXM4-Zp-Used-Tires-p/dec-406.htm"
                    listing_response = ''
                    (1..5).each do |i|
                        begin
                            listing_response = ReadData(tk_listing_url.to_s)
                            break
                        rescue Exception => e
                            puts "Error processing #{tk_listing_url} - #{e.to_s}"
                        end
                    end

                    if listing_response != ''
                        listing_data = Nokogiri::HTML(listing_response.to_s)
                        touched = 0

                        listing_description = listing_data.xpath("//span[@itemprop='description']").text()
                        info = /(\d{3})\/(\d{2})\/(\d{2}).*(#{manu_list}).(.*)[Uu]sed [Tt]ire.*/.match(listing_description)
                        info = /(\d{3})\/(\d{2})\/(\d{2}).*(#{manu_list}).(.*)\. This set.*/.match(listing_description) if info.nil?
                        info = /(\d{3})\/(\d{2})\/(\d{2}).*(#{manu_list}).(.*)\. This pair.*/.match(listing_description) if info.nil?

                        if !info
                            puts "Skipping #{tk_listing_url} - could not process."
                        else
                            sizestr = "#{info[1]}/#{info[2]}R#{info[3]}"
                            manu_name = translate_mfr_name(info[4].strip().gsub(nbsp, ''))
                            model_name = info[5].strip().gsub(nbsp, '')

                            tread = /(\d*\.\d)\/32nd/.match(listing_description)
                            tread = /(\d*)\/32nd/.match(listing_description) if !tread
                            if tread
                                remaining_tread = tread[1]
                            else
                                remaining_tread = ''
                            end

                            price_text = listing_data.xpath("//font[@class='pricecolor colors_productprice']").text()
                            price = /Our Price:.*\$(.*)/.match(price_text)
                            price = /Sale Price:.*\$(.*)/.match(price_text) if !price
                            if price
                                price_str = price[1]

                                manu = TireManufacturer.find_by_name(manu_name)
                                size = TireSize.find_by_sizestr(sizestr)
                                listing_title = listing_data.xpath("//span[@itemprop='name']").text().strip()
                                qty = /^\((\d)\)/.match(listing_title)
                                product_code_text = listing_data.xpath("//span[@class='product_code']").text().strip()

                                if !qty
                                    puts "*** NO QTY IN #{listing_title}"
                                end

                                if manu && size && qty
                                    model = TireModel.find(:first, :conditions => ["tire_manufacturer_id = ? and tire_size_id = ? and lower(name) = ?", manu.id, size.id, model_name.downcase])
                                    if model.nil?
                                        model = TireModel.find(:first, :conditions => ["tire_manufacturer_id = ? and tire_size_id = ? and lower(name) = ?", manu.id, size.id, translate_model_name(model_name).downcase])
                                    end

                                    if model.nil?
                                        # find best match
                                        matcher = FuzzyMatch.new(TireModel.find(:all,  :conditions => ['tire_manufacturer_id = ? and tire_size_id = ?', manu.id, size.id]), :read => :name)
                                        model = matcher.find(model_name)
                                        if model
                                            # check our confidence score
                                            con = confidence.getDistance(model.name.downcase, model_name.downcase)
                                            if con < 0.9
                                                model = nil
                                            else
                                                puts "Fuzzy match (#{con}) - #{model.name}/#{model_name}"
                                            end
                                        end
                                    end

                                    if model 
                                        valid_count += 1
                                        # Check and see if we've already listed this tire.
                                        # if not, create a new one
                                        tl = TireListing.find_by_redirect_to(tk_listing_url)
                                        if !tl
                                            tl = TireListing.new
                                        end

                                        photo1_url = listing_data.xpath("//a[@id='product_photo_zoom_url']").attribute("href").text().strip()
                                        #puts "#{photo1_url}"
                                        tl.photo1 = open("http:#{photo1_url}")

                                        begin
                                            photo2_url = listing_data.xpath("//span[@id='altviews']/a[2]/@href").text().strip()
                                            tl.photo2 = open("http:#{photo2_url}")
                                        rescue Exception => e
                                            puts "#{e.to_s} processing Photo2"
                                        end

                                        begin
                                            photo3_url = listing_data.xpath("//span[@id='altviews']/a[3]/@href").text().strip()
                                            tl.photo3 = open("http:#{photo3_url}")
                                        rescue Exception => e
                                            puts "#{e.to_s} processing Photo3"
                                        end

                                        begin
                                            photo4_url = listing_data.xpath("//span[@id='altviews']/a[4]/@href").text().strip()
                                            tl.photo4 = open("http:#{photo4_url}")
                                        rescue Exception => e
                                            puts "#{e.to_s} processing Photo4"
                                        end

                                        if product_code_text
                                            tire_store = tire_stores_hash[product_code_text[0..2]]
                                            records_added_hash[product_code_text[0..2]] += 1
                                        else
                                            tire_store = tire_stores_hash.first
                                            records_added_hash[0] += 1
                                        end

                                        if tire_store.nil?
                                            puts "Could not find store for #{product_code_text[0..2]} - #{tk_listing_url}"
                                        else
                                            tl.tire_store_id = tire_store.id
                                            tl.source = 'TireKingzAtl.com'
                                            tl.tire_manufacturer_id = manu.id
                                            tl.quantity = qty[1]
                                            tl.includes_mounting = false
                                            tl.remaining_tread = remaining_tread
                                            tl.tire_size_id = size.id
                                            tl.price = price_str
                                            tl.tire_model_id = model.id
                                            tl.is_new = false
                                            tl.stock_number = product_code_text if product_code_text
                                            tl.sell_as_set_only = true
                                            tl.redirect_to = tk_listing_url
                                            tl.save
                                        end

                                        #if !tl.new_record?
                                        #    tl.touch
                                        #    touched += 1
                                        #end
                                    else
                                        puts "#{tk_listing_url}"
                                        #puts "----> #{price_str}"
                                        #puts "---> Remaining tread: #{remaining_tread}" if tread
                                        puts "*** UNABLE TO FIND MODEL #{manu.name} #{sizestr} #{model_name} (#{translate_model_name(model_name)})"
                                    end
                                else
                                    if !manu 
                                        puts "*** Unable to find manufacturer #{manu_name}"
                                    end
                                    if !size 
                                        puts "*** Unable to find size #{sizestr}"
                                    end
                                end
                            else
                                puts "*** unable to process price #{price_text}"
                            end
                        end
                    end
                end
            end

            # which ones did we not touch?
            tire_stores_hash.each do |k, tire_store|
                untouched = TireListing.where("tire_store_id = ? and updated_at < ?", tire_store.id, start_time)
                untouched.each do |r|
                    puts "Deleting out of date: #{r.id} #{r.description}"
                    r.delete
                    records_deleted_hash[k] += 1                    
                end
            end
            #puts "Touched #{touched}"

            puts "Successfully processed #{valid_count} of #{html_data.xpath("//a[@class='productnamecolor colors_productname']/@href").count}"

            body_text = "Successfully processed #{valid_count} of #{html_data.xpath("//a[@class='productnamecolor colors_productname']/@href").count}\n\n"
            tire_stores_hash.each do |k, tire_store|
                body_text += "#{tire_store.name}\n"
                body_text += "---------------------------\n"
                body_text += "Added #{records_added_hash[k]}\n"
                body_text += "Deleted #{records_deleted_hash[k]}\n\n"
            end

            ActionMailer::Base.mail(:from => "mail@treadhunter.com", 
                :to => system_process_completion_email_address(), 
                :subject => "Processed Tire Kingz", 
                :body => "#{body_text}").deliver                          
        else
            puts "Unable to read URL: #{tk_url}.  Please check this URL to see if make and model were entered correctly."
        end
    end
end