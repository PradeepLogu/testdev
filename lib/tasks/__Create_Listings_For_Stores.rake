require 'nokogiri'
require 'rest_client'

namespace :CreateListingsOnly do
    desc "Create tirelistings for existing tire stores"
    task populate: :environment do
        teasers = [
                    "SET OF %s %s %s %s used tires",
                    "(%s) Nice %s %s %s Used Tires",
                    "Check out our (%s) used %s %s %s tires",
                    "We have %s used %s %s tires, size %s",
                    "Like new! (%s) used %s %s %s tires",
                    "If you need %s %s %s tires, size %s, we have 'em!",
                    "Count: %s  Brand: %s  Model: %s  Size: %s  *** LOOK INSIDE ***"
                  ]
        manufacturers = TireManufacturer.find(:all)
        models = TireModel.find(:all)
        tiresizes = TireSize.find(:all)
        tire_stores = TireStore.near("Atlanta, GA", 100)

        tire_stores.each do |tire_store|
            begin
                # now create some listings
                # how many should we create?  Random # between 10 and 60
                (rand(10)..(rand(50) + 10)).each do 
                    num_tires = rand(4) + 1
                    price_per_tire = (rand(7) + 1) * 10
                    model = models[rand(models.count)]

                    tl = TireListing.new()
                    tl.price = num_tires * price_per_tire
                    tl.status = 0
                    tl.tire_store_id = tire_store.id
                    tl.source = 'Randomly Generated'
                    tl.tire_size_id = model.tire_size_id

                    tl.tire_model_id = model.id

                    manu = nil
                    manufacturers.each do |m|
                        if m.id == model.tire_manufacturer_id
                            manu = m
                        end
                    end
                    #manu = TireManufacturer.find(model.tire_manufacturer_id)

                    ts = nil
                    tiresizes.each do |t|
                        if t.id == model.tire_size_id
                            ts = t
                        end
                    end
                    #ts = TireSize.find(model.tire_size_id)

                    tl.description = 'We have a set of %s used %s %s tires.  They are size %s.  Cost is %s - installed.  They have a treadlife of about %s.' %
                                        [num_tires.to_s, manu.name, model.name, ts.sizestr, (num_tires * price_per_tire).to_s, tl.treadlife.to_s]
                    tl.teaser = teasers[rand(teasers.count)] % [num_tires.to_s, manu.name, model.name, ts.sizestr]
                    tl.tire_manufacturer_id = model.tire_manufacturer_id
                    tl.quantity = num_tires
                    tl.includes_mounting = true if rand(2) > 0
                    tl.warranty_days = rand(31)

                    tl.orig_cost = (rand(4) + 3) * price_per_tire
                    
                    tl.remaining_tread = (rand(model.tread_depth - 2) + 2)
                    tl.crosspost_craigslist = true if rand(2) > 0
                    tl.save
                end
            rescue Exception => e 
                puts "We had an exception - skipping for now (" + e.message + ")."
            end
        end
    end
end
