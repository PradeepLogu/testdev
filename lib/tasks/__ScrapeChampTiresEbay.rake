require 'nokogiri'
require 'rest_client'
require 'fuzzystringmatch'

namespace :ScrapeChampTiresEbay do
    desc "Scrape ChampTires data from eBay"
    task populate: :environment do
        start_time = Time.now
        
        pa_store = TireStore.find_by_name_and_city('Champtires Pittsburgh', 'West Mifflin')
        if !pa_store
            puts "**** CREATING TIRESTORE RECORD"
            pa_store = TireStore.new
            pa_store.name = 'Champtires Pittsburgh'
            pa_store.address1 = '1130 Lebanon Road'
            pa_store.city = 'West Mifflin'
            pa_store.state = 'PA'
            pa_store.zipcode = '15122'
            pa_store.phone = '4125671447'
            pa_store.contact_email = 'kirick@treadhunter.com'
            pa_store.save
            pa_store.errors.each do |e|
                puts e.to_s 
            end
        end

        il_store = TireStore.find_by_name_and_city('Champtires Chicago', 'Chicago')
        if !il_store
            puts "**** CREATING TIRESTORE RECORD"
            il_store = TireStore.new
            il_store.name = 'Champtires Chicago'
            il_store.address1 = '2720 W Grand Ave'
            il_store.city = 'Chicago'
            il_store.state = 'IL'
            il_store.zipcode = '60612'
            il_store.phone = '7738773358'
            il_store.contact_email = 'kirick@treadhunter.com'
            il_store.save
            il_store.errors.each do |e|
                puts e.to_s 
            end
        end
        (1..20).each do |page| # 200
            sURL = "http://stores.ebay.com/Champtires/?_pgn=#{page}"
            response = RestClient.get sURL
            html_listings = Nokogiri::HTML(response.to_s)

            # this is used to match strings and tell us how close they are
            confidence = FuzzyStringMatch::JaroWinkler.create(:pure)

            listings = html_listings.xpath("//td[@class='details']/div/a")

            listings.each do |x|
                begin
                    response = RestClient.get x.attr('href')

                    ##puts "#{x.attr('href')}"
                    listing_page = Nokogiri::HTML(response.to_s)

                    title_str = listing_page.xpath("//h1").text.strip()

                    model = listing_page.xpath("//tr[contains(., 'Part Brand:')]/td[2]").text().gsub(/NEW/, '').strip()

                    qty_text = listing_page.xpath("//span[@id='qtySubTxt']").text().strip()
                    qty = /\d/.match(qty_text)
                    if !qty
                        qty = 1 # default
                    else
                        qty = qty[1]
                        qty = 4 if qty && qty.to_i > 4
                    end

                    manu = listing_page.xpath("//tr[contains(., 'Tire Brand:')]/td[4]").text.strip

                    size = /(P\d{3}\/\d{2}\/R\d{2})/.match(title_str)
                    if size
                        sizestr = size[1].gsub(/P/, '').gsub(/\/R/, 'R')
                    else
                        sizestr = ''
                    end

                    condition = listing_page.xpath("//div[@class='u-flL condText']").text().strip()
                    if condition == "New"
                        is_new = true 
                    else
                        is_new = false
                    end

                    price = listing_page.xpath('//span[@itemprop="price"]').text.gsub(/US \$/, '')
                    if price == ''
                        price = listing_page.xpath('//span[@id="mm-saleDscPrc"]').text.gsub(/US \$/, '')
                    end

                    tire_size = TireSize.find_by_sizestr(sizestr)
                    tire_manu = TireManufacturer.find_by_name(manu)

                    fuzzy_used = false

                    if !tire_manu
                        matcher = FuzzyMatch.new(TireManufacturer.find(:all), :read => :name)
                        tire_manu = matcher.find(manu)
                        if tire_manu
                            con = confidence.getDistance(tire_manu.name.downcase, manu.downcase)
                            if con < 0.9
                                fuzzy_used = false
                                tire_manu = nil
                            else
                                puts "FUZZY MFR: #{con}"
                                fuzzy_used = true
                            end
                        end
                    end

                    if tire_size && tire_manu
                        tire_model = TireModel.find_by_tire_manufacturer_id_and_tire_size_id_and_name(tire_manu.id, tire_size.id, model)
                        if !tire_model
                            # let's do a fuzzy match - see what happens!
                            matcher = FuzzyMatch.new(TireModel.find(:all,  :conditions => ['tire_manufacturer_id = ? and tire_size_id = ?', tire_manu.id, tire_size.id]), :read => :name)
                            tire_model = matcher.find(model)
                            if tire_model
                                # check our confidence score
                                con = confidence.getDistance(tire_model.name.downcase, model.downcase)
                                if con < 0.9
                                    fuzzy_used = false
                                    tire_model = nil
                                else
                                    puts "FUZZY MODEL: #{con}"
                                    fuzzy_used = true
                                end
                            end
                        end
                        if !tire_model
                            puts "Unable to find #{manu} #{sizestr} #{model}"
                        else
                            t = TireListing.find_by_redirect_to(x.attr('href'))
                            if !t
                                t = TireListing.new
                            end

                            begin
                                photo_url = listing_page.xpath("//img[@itemprop='image']").attribute("src").text().strip()
                                #puts "#{photo_url}"
                                t.photo1 = open("#{photo_url}") if photo_url && photo_url.is_valid_url?
                            rescue Exception => e
                                puts "---> error reading picture #{photo_url} - #{e.to_s}"
                            end

                            t.source = 'eBay.com'
                            t.includes_mounting = false
                            ###tl.stock_number = product_code_text if product_code_text
                            t.sell_as_set_only = false
                            t.tire_manufacturer_id = tire_manu.id
                            t.tire_model_id = tire_model.id
                            t.tire_size_id = tire_size.id
                            t.quantity = qty
                            t.is_new = is_new
                            t.price = price
                            remaining_tread = ""
                            if !is_new
                                begin
                                    treadstring = listing_page.xpath("//tr[contains(., 'Tread Depth:')]/td[4]").text.strip

                                    remaining_tread = /(\d{1,})\/32/.match(treadstring)
                                    t.remaining_tread = remaining_tread[remaining_tread.size - 1] if remaining_tread
                                rescue Exception => e
                                end
                            end

                            loc_element = listing_page.xpath("//div[contains(., 'Item location:') and contains(@class, 'iti-eu-label')]")
                            if loc_element && loc_element[0]
                                loc_text = loc_element[0].next_sibling().text().strip()
                            else
                                loc_text = ""
                            end

                            puts "#{x.attr('href')}"
                            puts "#{manu} #{model}"
                            puts "#{tire_manu.name} #{tire_model.name}"
                            puts "QTY: #{qty} SIZE: #{size} PRICE: #{price} NEW: #{is_new}"
                            puts "Loc: #{loc_text}"
                            puts "*************************"

                            if loc_text.include?('Penn') or loc_text.include?('Mifflin')
                                t.tire_store_id = pa_store.id
                            else
                                t.tire_store_id = il_store.id
                            end

                            t.redirect_to = x.attr('href')
                            t.save
                        end
                    else
                        puts "Unable to find #{manu} #{sizestr}"
                    end
                #rescue Exception => e
                    # couldn't parse this page, no big deal
                #    puts "ERROR - #{e.to_s}"
                end
            end 
        end

        # which ones did we not touch?
        untouched = TireListing.where("tire_store_id in (?, ?) and updated_at < ?", il_store.id, pa_store.id, start_time)
        untouched.each do |r|
            puts "Deleting out of date: #{r.id} #{r.description}"
            r.delete
        end
        #puts "Touched #{touched}"
    end
end
