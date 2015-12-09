require 'nokogiri'
require 'rest_client'

def parse_ebay_listings
    result = []

    (1..200).each do |page| # 200
        sURL = "http://stores.ebay.com/VYC-bestusedtires/?_localstpos=30092&_pgn=#{page}"
        response = RestClient.get sURL
        html_listings = Nokogiri::HTML(response.to_s)

        listings = html_listings.xpath("//td[@class='details']/div/a")

        listings.each do |x|
            begin
                response = RestClient.get x.attr('href')
                listing_page = Nokogiri::HTML(response.to_s)

                title_str = listing_page.xpath("//h1").text.strip()
                model = listing_page.xpath('//strong/font[@size="5"]')[3].text
                qty = title_str.split(' ')[0].strip
                manu = listing_page.xpath('//table[contains(., "Section Width")]//td')[7].text.strip
                size = listing_page.xpath('//table[contains(., "Section Width")]//td')[5].text.strip + '/' +
                    listing_page.xpath('//table[contains(., "Section Width")]//td')[9].text.strip + 'R' +
                    listing_page.xpath('//table[contains(., "Section Width")]//td')[15].text.strip

                is_new = listing_page.xpath('//table[contains(., "A tire that has been previously used")]').count == 0
                price = listing_page.xpath('//span[@itemprop="price"]').text.gsub(/US \$/, '')
                if price == ''
                    price = listing_page.xpath('//span[@id="mm-saleDscPrc"]').text.gsub(/US \$/, '')
                end
                found = false
                tire_size = TireSize.find_by_sizestr(size)
                if tire_size
                    tire_manu = TireManufacturer.find_by_name(manu)
                    if tire_manu
                        tire_model = TireModel.where('tire_manufacturer_id = ? and tire_size_id = ? and name ilike ?',
                                                        tire_manu.id, tire_size.id, '%' + model.split(' ')[0].strip + '%').first
                        #tire_model = TireModel.find_by_tire_manufacturer_id_and_tire_size_id_and_name(tire_manu.id, tire_size.id, model)
                        if tire_model
                            found = true
                        end
                    end
                end
                if found
                    puts "#{found} - #{qty}/#{manu}/#{model}/#{size}/#{price} - #{is_new}"
                    puts "   #{tire_size.sizestr} #{tire_manu.name} #{tire_model.name}"
                    puts ""
                    t = TireListing.new
                    t.tire_manufacturer_id = tire_manu.id
                    t.tire_model_id = tire_model.id
                    t.tire_size_id = tire_size.id
                    t.quantity = rand(qty.to_i) + 1
                    t.is_new = is_new
                    t.price = (t.quantity * (price.to_f / qty.to_i)) 
                    if !is_new
                        #t.remaining_tread = 
                        #t.treadlife = 
                        begin
                            treadstring = listing_page.xpath('//font[contains(., "Approximate") and contains(., "tread")]')[0].text.strip
                            m1 = /tread:\ [0123456789]*-*(\d{1,})\/32/.match(treadstring)
                            m2 = /(\d{1,})\%/.match(treadstring)
                            t.remaining_tread = m1[1]
                            t.treadlife = m2[0] 
                            puts "    Tread: #{t.remaining_tread} Life: #{t.treadlife}"
                        rescue
                            # couldn't get treadlife, we'll make him new :)
                            t.is_new = true
                        end
                    end
                    #puts "       New Qty - #{t.quantity}"
                    #puts "       New Price - #{t.price}"
                    t.description = listing_page.xpath('//img[@itemprop="image"]').attr('src').text.strip
                    #puts "     #{t.description}"
                    result << t
                else
                    #puts "fail"
                end
            rescue
                # couldn't parse this page, no big deal
                #puts "ERROR"
            end
        end 
    end

    puts "We found #{result.count} listings we could use."
    result
end

def get_random_listing(listings_array)
    i = rand(listings_array.count - 1) #+ 1

    return listings_array.delete_at(i)
end

def get_random_user(user_array)
    i = rand(user_array.count - 1) + 1
    while user_array[i].split(',')[0] == 'female'
        user_array.delete_at(i)
        i = rand(user_array.count - 1) + 1
    end
    s = user_array.delete_at(i)

    user_attr = s.split(',')

    u = User.new(:email => user_attr[1],
                    :first_name => user_attr[3],
                    :last_name => user_attr[4],
                    :password => 'treadhunter',
                    :password_confirmation => 'treadhunter',
                    :phone => '888-555-1212',
                    :tireseller => true)
end

def get_random_street_name
    street_urls = [
        'http://www.livingplaces.com/streets/A.html',
        'http://www.livingplaces.com/streets/B.html',
        'http://www.livingplaces.com/streets/C.html',
        'http://www.livingplaces.com/streets/D.html',
        'http://www.livingplaces.com/streets/E.html',
        'http://www.livingplaces.com/streets/F.html',
        'http://www.livingplaces.com/streets/G.html',
        'http://www.livingplaces.com/streets/H.html',
        'http://www.livingplaces.com/streets/I.html',
        'http://www.livingplaces.com/streets/J.html',
        'http://www.livingplaces.com/streets/K.html',
        'http://www.livingplaces.com/streets/L.html',
        'http://www.livingplaces.com/streets/M.html',
        'http://www.livingplaces.com/streets/N.html',
        'http://www.livingplaces.com/streets/O.html',
        'http://www.livingplaces.com/streets/P.html',
        'http://www.livingplaces.com/streets/Q.html',
        'http://www.livingplaces.com/streets/R.html',
        'http://www.livingplaces.com/streets/S.html',
        'http://www.livingplaces.com/streets/T.html',
        'http://www.livingplaces.com/streets/U.html',
        'http://www.livingplaces.com/streets/V.html',
        'http://www.livingplaces.com/streets/W.html',
        'http://www.livingplaces.com/streets/X.html',
        'http://www.livingplaces.com/streets/Y.html',
        'http://www.livingplaces.com/streets/Z.html',
        'http://www.livingplaces.com/streets/1.html',
        'http://www.livingplaces.com/streets/2.html',
        'http://www.livingplaces.com/streets/3.html',
        'http://www.livingplaces.com/streets/4.html',
        'http://www.livingplaces.com/streets/5.html',
        'http://www.livingplaces.com/streets/6.html',
        'http://www.livingplaces.com/streets/7.html',
        'http://www.livingplaces.com/streets/8.html',
        'http://www.livingplaces.com/streets/9.html'
    ]

    i = rand(street_urls.count)

    sURL = street_urls[i]
    response = RestClient.get sURL
    html_street_names = Nokogiri::HTML(response.to_s)

    streets = html_street_names.xpath("//td/a")

    return streets[rand(streets.count)].text.strip
end

def get_random_storename(tire_store, street_name, user)
    # given a TireStore record, a street name, and a user, let's generate a pseudo-random name
    # for the business
    case rand(13)
    when 0
        return "#{user.first_name}'s Used Tires"
    when 1
        return "Best Used Tires of #{tire_store.city}"
    when 2
        return "#{street_name} Tires"
    when 3
        return "#{user.last_name} Tires"
    when 4
        return "#{tire_store.city}'s Tire Emporium"
    when 5
        return "Quality Tires By #{user.first_name}"
    when 6
        return "#{tire_store.city} Tire and Auto"
    when 7
        return "#{user.last_name} Tire and Auto"
    when 8
        return "#{tire_store.city} Discount Tires"
    when 9
        return "#{tire_store.city} Tires Plus"
    when 10
        return "#{tire_store.city} Tires and Wheels"
    when 11
        return "#{user.last_name} Total Car Care"
    when 12
        return "#{user.last_name} Tire Company"
    end
end

def get_prices_from_google(search_str)
    begin
        url = "https://www.google.com/search?output=search&tbm=shop&q=#{search_str}"
        search_response = ReadData url
        search_page = Nokogiri::HTML(search_response.to_s)

        all_prices = search_page.xpath("//span[@class='price']")
        puts search_response
        puts all_prices
    rescue
        puts "Oops"
        return nil
    end
end

namespace :SeedBetaListings do
    desc "Create listings"
    task populate: :environment do
        arListings = parse_ebay_listings

        arListings.each do |l|
            begin
                l.photo1 = open(l.description)
                l.description = ''
                l.source = 'seed'
                l.tire_store_id = 0
                l.save
            rescue
                puts "Failed saving picture for #{l.description}"
            end
        end
    end
end

namespace :PopulateBetaWithListings do
    desc "Populate with listings"
    task populate: :environment do
        @all_sizes = TireSize.all
        TireStore.all.each do |t|
            listings_per_store = (rand(400) + 100)
            (0..listings_per_store).each do |i|
                random_size = @all_sizes[rand(@all_sizes.size) - 1]

                @all_models = TireModel.find(:all, :conditions => ["tire_size_id = ? and manu_part_num > ''", random_size.id])
                random_model = @all_models[rand(@all_models.size) - 1]
                
                if random_model
                    #search_str = CGI.escape("#{random_size.sizestr} #{random_model.tire_manufacturer.name} #{random_model.name} #{random_model.manu_part_num}")
                    #avg_prices = get_prices_from_google(search_str)
                    puts "#{t.name} #{random_size.sizestr} #{random_model.tire_manufacturer.name} #{random_model.name}"
                    tl = TireListing.new
                    tl.tire_store_id = t.id
                    tl.source = 'PopulateBetaWithListings'
                    tl.tire_manufacturer_id = random_model.tire_manufacturer_id
                    tl.quantity = 4
                    tl.includes_mounting = false
                    tl.tire_size_id = random_size.id
                    tl.price = (rand(30000) + 6000) / 100
                    tl.tire_model_id = random_model.id
                    tl.is_new = true
                    tl.stock_number = random_model.manu_part_num
                    tl.sell_as_set_only = false
                    tl.save
                end
            end
        end
    end
end

namespace :FlattenTirePrices do
    desc "Flatten tire prices"
    task populate: :environment do
        @all_models = TireListing.all.map(&:tire_model_id).uniq
        @all_models.each do |model_id|
            @listings = TireListing.find_all_by_tire_model_id(model_id)
            if @listings.size > 1
                avg_price = @listings.map(&:price).inject{|sum,el| sum + el}.to_f / @listings.size

                @listings.each do |l|
                    percent_diff = (rand(10) * (rand > 0.5 ? 1.0 : -1.0)).to_f
                    dollars_diff = avg_price * (percent_diff / 100.0)
                    new_price = Money.new((avg_price + dollars_diff) * 100)

                    puts "#{model_id} - #{@listings.size} - avg: #{avg_price} diff: #{percent_diff} new: #{new_price}"

                    l.price = new_price
                    l.save
                end
            end
        end
    end
end

namespace :CreatePopularListingsForBeta do
    desc "Create listings for popular vehicles"
    task populate: :environment do 
        all_tire_store_ids = [138, 147, 4, 140, 145, 60, 146, 132, 141, 82]
        all_tire_size_ids = []
        total_models = 0

        ["Altima", "Accord", "Civic", "Camry"].each do |car|
            auto_model = AutoModel.find_by_name(car)
            auto_model.auto_years.each do |year|
                year.auto_options.each do |option|
                    if !all_tire_size_ids.include?(option.tire_size_id)
                        all_tire_size_ids << option.tire_size_id
                    end
                end
            end
        end

        all_tire_size_ids.each do |tire_size_id|
            t = TireSize.find(tire_size_id)
            total_models += t.tire_models.size

            # we're going to create 15 to 25 listings per store per size
            num_listings = 15 + rand(10)
            puts "Gonna create #{num_listings} for size #{t.sizestr}"

            (1..num_listings).each do |i|
                tire_model = t.tire_models[rand(t.tire_models.size)]
                base_price = 15000 + rand(10000) # $150 - $250 ea
                all_tire_store_ids.each do |ts_id|
                    tire_store = TireStore.find(ts_id)

                    diff = base_price * (rand(-10..10) / 100.00)
                    tire_price = Money.new(base_price + diff)

                    puts "Store: #{tire_store.name}, Model: #{tire_model.name}, Size: #{t.sizestr}, Price: #{tire_price}"
                    tire_listing = TireListing.new
                    tire_listing.tire_store_id = tire_store.id
                    tire_listing.source = 'CreatePopularListingsForBeta'
                    tire_listing.tire_manufacturer_id = tire_model.tire_manufacturer_id
                    tire_listing.quantity = 4
                    tire_listing.includes_mounting = false
                    tire_listing.tire_size_id = tire_size_id
                    tire_listing.price = tire_price
                    tire_listing.tire_model_id = tire_model.id
                    tire_listing.is_new = true
                    tire_listing.sell_as_set_only = false
                    tire_listing.save
                end
            end
        end

        puts "Total models: #{total_models}"
        puts "Tire sizes: #{all_tire_size_ids.size}"
    end
end

namespace :SeedBetaSite do
    desc "Seed the Beta Site"
    task populate: :environment do
        cities = [
                    #"new-york-ny", 
                    #"los-angeles-ca", 
                    #"chicago-il", 
                    #"houston-tx",
                    #"philadelphia-pa",
                    #"phoenix-az",
                    #"san-antonio-tx",
                    #"san-diego-ca",
                    #"dallas-tx",
                    #"san-jose-ca",
                    "jacksonville-fl",
                    #"indianapolis-in",
                    #"san-francisco-ca",
                    #"austin-tx",
                    #"columbus-oh",
                    #"fort-worth-tx",
                    "charlotte-nc",
                    #"detroit-mi",
                    #"el-paso-tx",
                    "memphis-tn",
                    #"baltimore-md",
                    #"boston-ma",
                    #"seattle-wa",
                    #"washington-dc",
                    "nashville-tn",
                    #"denver-co",
                    #"louisville-ky",
                    #"milwaukee-wi",
                    #"portland-or",
                    #"las-vegas-nv",
                    #"oklahoma-city-ok",
                    #"albuquerque-nm",
                    #"tucson-az",
                    #"fresno-ca",
                    #"sacramento-ca",
                    #"long-beach-ca",
                    #"kansas-city-mo",
                    #"mesa-az",
                    #"virginia-beach-va",
                    #####"atlanta-ga",
                    #"colorado-springs-co",
                    #"omaha-ne",
                    "raleigh-nc",
                    "miami-fl",
                    #"cleveland-oh",
                    #"tulsa-ok",
                    #"oakland-ca",
                    #"minneapolis-mn",
                    #"wichita-ks",
                    #"arlington-tx",
                    #####"parsons-ks"
                 ]

        arListings = TireListing.where('tire_store_id = 0')

        user_array = IO.readlines('/Users/Kevin/Downloads/FakeNameGenerator-1/FakeNameGenerator.com_9538273d.csv')

        cities.each do |city|
            cityURL = "http://dev.virtualearth.net/REST/v1/Locations/#{city}?key=ArW5u_MZDCbLaSabVyXCaOxN18AZnpdQawOJYvUlz33z9Uq9GYWz-a4ycWvk_6F2"

            # first get the lat/lon for this city
            response = RestClient.get cityURL
            parsedJSON = JSON.parse(response)

            latitude = parsedJSON["resourceSets"][0]["resources"][0]["geocodePoints"][0]["coordinates"][0]
            longitude = parsedJSON["resourceSets"][0]["resources"][0]["geocodePoints"][0]["coordinates"][1]
            city_state = parsedJSON["resourceSets"][0]["resources"][0]["name"]

            city = city_state.split(',')[0].strip
            state = city_state.split(',')[1].strip

            # now draw a grid around the city and start generating users and stores
            startLat = latitude - 1
            endLat = latitude + 1
            startLon = longitude - 1
            endLon = longitude + 1

            count = 0

            while startLon <= endLon
                curLat = startLat
                while curLat <= endLat
                    # create a user
                    u = get_random_user(user_array)

                    # create a tire store
                    street = get_random_street_name()

                    t = TireStore.new
                    t.city = city
                    t.state = state
                    t.zipcode = '99999'
                    t.address1 = (rand(500) + 100).to_s + ' ' + street
                    t.phone = '770-555-1212'

                    t.name = get_random_storename(t, street, u)
                    t.latitude = curLat
                    t.longitude = startLon

                    a = Account.new
                    a.name = t.name
                    a.phone = '888-555-1212'
                    a.address1 = t.address1
                    a.city = city
                    a.state = state
                    a.zipcode = '99999'
                    a.save

                    u.account_id = a.id

                    t.save
                    u.save

                    t.update_attribute(:latitude, curLat)
                    t.update_attribute(:longitude, startLon)

                    puts "Account - #{a.id} Store - #{t.id} / #{t.name}/#{t.address1}/#{t.city}, #{t.state} #{t.latitude}/#{t.longitude}"

                    # now create listings.  Let's try somewhere between 50 and 100 per store?
                    (rand(50)..(rand(50) + 50)).each do
                        l = nil 
                        while !l
                            l = get_random_listing(arListings)
                            if l
                                begin
                                    l.tire_store_id = t.id
                                    ##l.photo1 = open(l.description)
                                    ##l.description = ''
                                    ##l.source = 'seed'
                                    l.save
                                rescue
                                    puts "Exception loading picture for #{l.description}"
                                end
                            end
                        end
                    end

                    curLat += 0.5
                end

                startLon += 0.5
            end
        end
    end
end
