require 'nokogiri'
require 'rest_client'

namespace :BogusNationalData do
    desc "Create tirelistings for Top 50 cities"
    task populate: :environment do
        teasers = [
                    "SET OF %s %s %s used tires",
                    "(%s) Nice %s %s Used Tires",
                    "Check out our (%s) used %s %s tires",
                    "We have %s used %s tires, size %s",
                    "Like new! (%s) used %s %s tires",
                    "If you need %s %s tires, size %s, we have 'em!",
                    "Count: %s  Brand: %s  Size: %s  *** LOOK INSIDE ***"
                  ]
        manufacturers = TireManufacturer.find(:all)
        models = TireModel.find(:all)
        tiresizes = TireSize.find(:all)
        cities = [
                    "new-york-ny", 
                    "los-angeles-ca", 
                    "chicago-il", 
                    "houston-tx",
                    "philadelphia-pa",
                    "phoenix-az",
                    "san-antonio-tx",
                    "san-diego-ca",
                    "dallas-tx",
                    "san-jose-ca",
                    "jacksonville-fl",
                    "indianapolis-in",
                    "san-francisco-ca",
                    "austin-tx",
                    "columbus-oh",
                    "fort-worth-tx",
                    "charlotte-nc",
                    "detroit-mi",
                    "el-paso-tx",
                    "memphis-tn",
                    "baltimore-md",
                    "boston-ma",
                    "seattle-wa",
                    "washington-dc",
                    "nashville-tn",
                    "denver-co",
                    "louisville-ky",
                    "milwaukee-wi",
                    "portland-or",
                    "las-vegas-nv",
                    "oklahoma-city-ok",
                    "albuquerque-nm",
                    "tucson-az",
                    "fresno-ca",
                    "sacramento-ca",
                    "long-beach-ca",
                    "kansas-city-mo",
                    "mesa-az",
                    "virginia-beach-va",
                    "atlanta-ga",
                    "colorado-springs-co",
                    "omaha-ne",
                    "raleigh-nc",
                    "miami-fl",
                    "cleveland-oh",
                    "tulsa-ok",
                    "oakland-ca",
                    "minneapolis-mn",
                    "wichita-ks",
                    "arlington-tx"
                 ]
        cities.each do |city|
            # seven pages of stores per city
            (1..7).each do |i|
                tirestoresurl = "http://www.yellowpages.com/" + city + "/used-tire-dealers?page=" + i.to_s
                puts tirestoresurl
                tire_store_response = RestClient.get tirestoresurl
                html_tire_listings = Nokogiri::HTML(tire_store_response.to_s)

                html_tire_listings.xpath("//div[@class='listing_content']").each do |tirestore|
                    store_name  = tirestore.xpath("div/div/h3").text().strip()
                    store_addr  = tirestore.xpath("div/span[@class='listing-address adr']/span[@class='street-address']").text().strip().chomp(',')
                    store_city  = tirestore.xpath("div/span[@class='listing-address adr']/span[@class='city-state']/span[@class='locality']").text().strip()
                    store_state = tirestore.xpath("div/span[@class='listing-address adr']/span[@class='city-state']/span[@class='region']").text().strip()
                    store_zip   = tirestore.xpath("div/span[@class='listing-address adr']/span[@class='city-state']/span[@class='postal-code']").text().strip()
                    store_phone = tirestore.xpath("div/span[@class='business-phone phone']").text().strip()
                    store_lat   = tirestore.xpath("span[@class='geo hidden']/span[@class='latitude']").text().strip()
                    store_lon   = tirestore.xpath("span[@class='geo hidden']/span[@class='longitude']").text().strip()

                    if !store_name.blank? and !store_addr.blank? and !store_city.blank? and
                        !store_state.blank? and !store_zip.blank? and !store_lat.blank? and !store_lon.blank?

                        begin

                            puts "name:" + store_name
                            puts "addr:" + store_addr
                            puts "city:" + store_city + "/" + store_state + "/" + store_zip
                            puts "phone:" + store_phone
                            puts "lat/lon:" + store_lat + ", " + store_lon
                            puts ""

                            # see if we have an account for this store name yet, if not we'll create one
                            account = Account.find_by_name(store_name)
                            if account.nil?
                                account = Account.new()
                                account.name = store_name
                                account.address1 = store_addr
                                account.city = store_city
                                account.state = store_state
                                account.zipcode = store_zip
                                account.phone = store_phone
                                account.save
                            end

                            t = TireStore.new()
                            t.account_id = account.id 
                            t.name = store_name
                            t.address1 = store_addr
                            t.city = store_city
                            t.state = store_state
                            t.zipcode = store_zip
                            t.latitude = store_lat
                            t.longitude = store_lon
                            t.phone = store_phone
                            t.save

                            # now create some listings
                            # how many should we create?  Random # between 10 and 60
                            (rand(10)..(rand(50) + 10)).each do 
                                num_tires = rand(4) + 1
                                price_per_tire = (rand(7) + 1) * 10
                                manu = manufacturers[rand(manufacturers.count)]
                                ts = tiresizes[rand(tiresizes.count)]
                                tl = TireListing.new()
                                tl.treadlife = (rand(7) + 3) * 10
                                tl.price = num_tires * price_per_tire
                                tl.status = 0
                                tl.tire_store_id = t.id
                                tl.source = 'Randomly Generated'
                                tl.tire_size_id = ts.id
                                tl.description = 'We have a set of %s used %s tires.  They are size %s.  Cost is %s - installed.  They have a treadlife of about %s.' %
                                                    [num_tires.to_s, manu.name, ts.sizestr, (num_tires * price_per_tire).to_s, tl.treadlife.to_s]
                                tl.teaser = teasers[rand(teasers.count)] % [num_tires.to_s, manu.name, ts.sizestr]
                                tl.tire_manufacturer_id = manu.id
                                tl.quantity = num_tires
                                tl.includes_mounting = true if rand(2) > 0
                                tl.warranty_days = rand(31)
                                tl.orig_cost = (rand(4) + 3) * price_per_tire
                                tl.remaining_tread = (rand(22) + 8).to_s + '/32'
                                tl.crosspost_craigslist = true if rand(2) > 0
                                tl.save
                            end
                        rescue Exception => e 
                            puts "We had an exception - skipping for now (" + e.message + ")."
                        end
                    end
                end
            end
        end
    end
end
