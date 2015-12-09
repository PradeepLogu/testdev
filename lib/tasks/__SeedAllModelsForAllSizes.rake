require 'nokogiri'
require 'rest_client'

namespace :SeedAllModelsForAllSizes do
    desc "Seed a Store with All Sizes"
    task populate: :environment do
        store = TireStore.find(126)
        ts = TireSize.find_by_sizestr('205/55R16')
        ts.tire_models.each do |tm|
            if ['Dunlop', 'Goodyear', 'BF Goodrich', 'Continental', 'Falken'].include?tm.tire_manufacturer.name
                l = TireListing.new
                l.quantity = 4
                l.treadlife = 100
                l.price = rand(100) + 100
                l.status = 0
                l.tire_store_id = store.id
                l.source = 'Randomly Generated'
                l.tire_size_id = ts.id
                l.tire_model_id = tm.id
                l.tire_manufacturer_id = tm.tire_manufacturer_id
                l.includes_mounting = true 
                l.is_new = true
                l.save
            end
        end
    end
end
