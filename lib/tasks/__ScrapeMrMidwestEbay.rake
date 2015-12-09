require 'nokogiri'
require 'rest_client'
require 'fuzzystringmatch'

namespace :ScrapeMrMidwestEbay do
    desc "Scrape Mr Midwest data from eBay"
    task populate: :environment do
        start_time = Time.now
        
        wi_store = TireStore.find_by_name_and_city('Mr. Midwest LLC', 'Madison')
        if !wi_store
            puts "**** CREATING TIRESTORE RECORD"
            wi_store = TireStore.new
            wi_store.name = 'Mr. Midwest LLC'
            wi_store.address1 = '530 Rolfsmeyer Dr'
            wi_store.city = 'Madison'
            wi_store.state = 'WI'
            wi_store.zipcode = '53713'
            wi_store.phone = '6083081000'
            wi_store.contact_email = 'mrmidwestllc@gmail.com'
            wi_store.save
            wi_store.errors.each do |e|
                puts e.to_s 
            end
        end

        (1..20).each do |page| # 200
            sURL = "http://www.ebay.com/sch/m.html?_ssn=mr.midwestllc&_pgn=#{page}"
            response = RestClient.get sURL
            html_listings = Nokogiri::HTML(response.to_s)

            # this is used to match strings and tell us how close they are
            confidence = FuzzyStringMatch::JaroWinkler.create(:pure)

            listings = html_listings.xpath("//td[contains(@class, 'dtl')]/div/h3/a")

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

                    size = /(\d{3}\/\d{2}Z*[\-R\/]\d{2})/.match(title_str)
                    if size
                        sizestr = size[1].gsub(/\-/, 'R').gsub(/Z/, '')
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
                    puts "SIZE: #{sizestr}"
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

                            t.tire_store_id = wi_store.id

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
        untouched = TireListing.where("tire_store_id in (?) and updated_at < ? and source = 'eBay.com'", wi_store.id, start_time)
        untouched.each do |r|
            puts "Deleting out of date: #{r.id} #{r.description}"
            r.delete
        end
        #puts "Touched #{touched}"
    end
end

def parse_price(str)
    @strip_from_price ||= ["price", "for", "tires", "only", "both", "is", "t", "price $", "[...]"]
    price = str.split.delete_if{|x| @strip_from_price.include?(x.downcase)}.join(' ').gsub(/\$/, '')
    return price.strip
end

def parse_manu_and_model(str, tire_size_id)
    @confidence ||= FuzzyStringMatch::JaroWinkler.create(:pure)

    @manu_matcher ||= FuzzyMatch.new(TireManufacturer.find(:all), :read => :name)
    @model_matcher ||= FuzzyMatch.new(TireModel.find(:all), :read => :name)

    tire_manu = tire_model = nil

    @strip_from_manu_model ||= ["complete", "matching", "set", "pair", "of", "four", "(4)", "two", "(2)", "nice", "used", "new"]
    manu_and_model = str.split.delete_if{|x| @strip_from_manu_model.include?(x.downcase)}.join(' ')

    # now parse out the manu and model
    manu_str = manu_and_model.split(" ").first
    model_str = manu_and_model.split(" ")[1..99].join(" ")

    tire_manu = TireManufacturer.find_by_name(manu_str)
    fuzzy_used = false

    if !tire_manu
        tire_manu = @manu_matcher.find(manu_str)
        if tire_manu
            con = @confidence.getDistance(tire_manu.name.downcase, manu_str.downcase)
            if con < 0.9
                @manu_errors << "Unable to find a match for #{manu_str}"
                fuzzy_used = false
                tire_manu = nil
            else
                #puts "FUZZY MFR: #{con}"
                fuzzy_used = true
            end
        end
    end

    if !tire_manu.nil?
        # let's find a model
        matching_models = @model_matcher.find_all(model_str)
        if matching_models
            max_confidence = 0
            best_match_model = nil
            matching_models.each do |m|
                if m.tire_size_id == tire_size_id && m.tire_manufacturer_id == tire_manu.id
                    con = @confidence.getDistance(m.name.downcase, model_str.downcase)
                    if con > 0.9
                        if con > max_confidence
                            # this is our best match so far
                            max_confidence = con 
                            best_match_model = m

                            break if con == 1.0
                        end
                    end
                end
            end
            if !best_match_model.nil?
                if max_confidence > 0.985
                    puts "#{max_confidence} - #{model_str} matched #{best_match_model.name}"
                    tire_model = best_match_model
                else
                    puts "#{max_confidence} - ALMOST MATCHED #{model_str} matched #{best_match_model.name}"
                end
            end
        end
    end

    if tire_manu.nil? || tire_model.nil?
        puts "*** could not match #{manu_str} #{model_str}"
    end

    return tire_manu, tire_model
end

def parse_size(str)
    tiresize1 = nil
    m1 = /(\d{2,}\/\d{2,}R*\d{2,})/.match(str)
    if m1
        tiresize1 = TireSize.find_by_sizestr(m1[1])
    end
    return tiresize1
end

def parse_photos(url)
    result = []
    response = RestClient.get url
    html_listings = Nokogiri::HTML(response.to_s)
    html_listings.xpath("//div[@id='thumbs']/a").each do |x|
        img_url = x.attribute("href").text().gsub(/_50x50c/, "_600x450").strip
        if result.size < 4
            result << img_url
        end
    end

    return result
end

def parse_stock_num(str)
    return str.gsub(/Stock\ \#/, '').strip
end

def parse_tread_depth(str)
    remaining_tread = /(\d{1,}\.*\d{0,})\-*.*\/32/.match(str)
    ##puts "#{remaining_tread.size}"
    return remaining_tread[1].strip
end

def parse_quantity(str)
    result = ""

    if str.downcase.include?("complete matching set of")
        result = "4"
    elsif str.downcase.include?("matching pair")
        result = "2"
    elsif str.downcase.include?("(2)")
        result = "2"
    elsif str.downcase.include?("(4)")
        result = "4"
    else
        result = ""
    end

    return result
end

namespace :ScrapeMrMidwestCraigslist do
    desc "Create tirelistings for TireKingz from Craigslist data"
    task populate: :environment do
        start_time = Time.now
        t = TireStore.find_by_name_and_city('Mr. Midwest LLC', 'Madison')
        if !t
            puts "**** CREATING TIRESTORE RECORD"
            t = TireStore.new
            t.name = 'Mr. Midwest LLC'
            t.address1 = '530 Rolfsmeyer Dr'
            t.city = 'Madison'
            t.state = 'WI'
            t.zipcode = '53713'
            t.phone = '6083081000'
            t.contact_email = 'mrmidwestllc@gmail.com'
            t.save
            t.errors.each do |e|
                puts e.to_s 
            end
        end        

        offset = 0
        good = bad = 0

        @other_errors = []
        @size_errors = []
        @manu_errors = []
        @model_errors = []
        @price_errors = []
        @stock_errors = []
        @tread_errors = []
        @qty_errors = []

        feed = RSS::Parser.parse(open('http://madison.craigslist.org/search/sss?query=mr+midwest&srchType=A&format=rss&s=' + offset.to_s).read, false)
        while feed.items.count > 0 do
            feed.items.each do |i|
                old_listing = TireListing.find_by_tire_store_id_and_teaser(t.id, i.about)
                if old_listing
                    good += 1
                    puts "Skipping because already there..."
                    @other_errors << "Skipped #{i.about} - already processed."
                    old_listing.touch(:updated_at)
                    next
                end

                tire_size = parse_size(i.title)
                if tire_size
                    j = 0
                    stock_num = price = quantity = tread_depth = description = ""
                    tire_manu = tire_model = nil
                    i.description.split("\n").each do |s|
                        if j == 0
                            puts "Trying to match #{s}"
                            tire_manu, tire_model = parse_manu_and_model(s, tire_size.id)
                            if tire_manu.nil? 
                                bad += 1
                                @manu_errors << "#{i.dc_source} Could not process manufacturer #{s}"
                                break
                            elsif tire_model.nil?
                                bad += 1
                                @model_errors << "#{i.dc_source} Could not process model #{s}"
                                break
                            end

                            quantity = parse_quantity(s)
                            if quantity.blank?
                                @qty_errors << "#{i.dc_source} Could not parse quantity: #{s}"
                                puts "BAD QTY: #{s}"
                            end
                        end
                        
                        if s.start_with?("Stock")
                            stock_num = parse_stock_num(s)
                            if stock_num.blank?
                                @stock_errors << "#{i.dc_source} Could not parse stock number: #{s}"
                            end
                        elsif s.start_with?("Price")
                            price = parse_price(s)
                            if price.blank?
                                @price_errors << "#{i.dc_source} Could not parse price: #{s}"
                            end
                        elsif s.start_with?("Tread depth")
                            tread_depth = parse_tread_depth(s)
                            if tread_depth.blank?
                                @tread_errors << "#{i.source} Could not parse tread depth: #{s}"
                            end
                        elsif s.downcase.include?('dot date') || s.downcase.include?('notes:')
                            description += s + "\n"
                        end

                        j += 1
                    end

                    if tire_manu && tire_model
                        if stock_num.blank? || price.blank? || tread_depth.blank? || quantity.blank?
                            puts "we have blank so screw it"
                            bad += 1
                        else
                            pics = parse_photos(i.about)

                            listing = TireListing.new
                            listing.tire_store_id = t.id
                            listing.tire_manufacturer_id = tire_manu.id
                            listing.tire_model_id = tire_model.id
                            listing.tire_size_id = tire_size.id
                            listing.is_new = false
                            listing.price = price 
                            listing.remaining_tread = tread_depth
                            listing.includes_mounting = false
                            listing.source = "craigslist"
                            listing.quantity = quantity
                            listing.teaser = i.about

                            listing.description = description
                            
                            begin
                                listing.photo1 = open(pics[0]) if pics && pics.size >= 1
                                listing.photo2 = open(pics[1]) if pics && pics.size >= 2
                                listing.photo3 = open(pics[2]) if pics && pics.size >= 3
                                listing.photo4 = open(pics[3]) if pics && pics.size >= 4
                            rescue Exception => e 
                                # prolly a timeout
                            end

                            if listing.save
                                good += 1
                            else
                                bad += 1
                                listing.errors.each do |e|
                                    @other_errors << "#{i.source} #{e.to_s}"
                                end
                            end

                            if false
                                puts "#{i.description}"
                                puts "===================="
                                puts "#{tire_size.sizestr} #{tire_manu.name} #{tire_model.name}"
                                puts "Stock#: #{stock_num}"
                                puts "Price: #{price}"
                                puts "Tread: #{tread_depth}"
                            end
                            #puts i.methods.join('-->')
                            #i.instance_values.each do |k, v|
                            #    puts "#{k} = #{v}"
                            #end
                            #puts i.content_encoded
                        end
                    end                    
                else
                    bad += 1
                    @size_errors << "Could not find a size in #{i.title}"
                end            
                puts "-----------------------------------------------"
            end
            offset = offset + 25
            feed = RSS::Parser.parse(open('http://madison.craigslist.org/search/sss?query=mr+midwest&srchType=A&format=rss&s=' + offset.to_s).read, false)
        end

        untouched = TireListing.where("tire_store_id in (?) and updated_at < ? and source = 'craigslist'", t.id, start_time)
        untouched.each do |r|
            puts "Deleting out of date: #{r.id} #{r.description}"
            r.delete
        end
        #puts "Touched #{touched}"        

        puts "Loaded #{good} records, failed on #{bad} records."
        sAllErrors = []
        if @manu_errors.size > 1
            sAllErrors << "Manufacturer processing errors"
            sAllErrors << "------------------------------"
            @manu_errors.each do |s|
                sAllErrors << s
            end
            sAllErrors << "     "
        end
        if @model_errors.size > 1
            sAllErrors << "Model processing errors"
            sAllErrors << "------------------------------"
            @model_errors.each do |s|
                sAllErrors << s
            end
            sAllErrors << "     "
        end
        if @stock_errors.size > 1
            sAllErrors << "Stock number processing errors"
            sAllErrors << "------------------------------"
            @stock_errors.each do |s|
                sAllErrors << s
            end
            sAllErrors << "     "
        end
        if @price_errors.size > 1
            sAllErrors << "Price processing errors"
            sAllErrors << "------------------------------"
            @price_errors.each do |s|
                sAllErrors << s
            end
            sAllErrors << "     "
        end
        if @tread_errors.size > 1
            sAllErrors << "Tread depth processing errors"
            sAllErrors << "------------------------------"
            @tread_errors.each do |s|
                sAllErrors << s
            end
            sAllErrors << "     "
        end
        if @other_errors.size > 1
            sAllErrors << "Other processing errors"
            sAllErrors << "------------------------------"
            @other_errors.each do |s|
                sAllErrors << s
            end
            sAllErrors << "     "
        end

        ActionMailer::Base.mail(:from => "mail@treadhunter.com", 
            :to => system_process_completion_email_address, 
            :subject => "Processed Mr Midwest", 
            :body => "#{good} added, #{bad} not added.\n\n" + sAllErrors.join("\n")).deliver              
    end
end
