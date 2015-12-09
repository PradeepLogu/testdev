namespace :FixRedundantTireSizes do
    desc "Fix redundant tire sizes"
    task populate: :environment do
        sql = "select sizestr, count(*) from tire_sizes group by sizestr having count(*) > 1 order by count(*) desc"
        bad_sizes = TireSize.connection.execute(sql)
        bad_sizes.each do |size|
            good_id = 0
            all_sizes = TireSize.find_all_by_sizestr(size["sizestr"], :order => "created_at")
            all_sizes.each do |s|
                if s == all_sizes.first
                    good_id = s.id
                else
                    puts "Need to change #{s.id} to #{good_id} (#{s.sizestr})"
                    tireModels = TireModel.find_all_by_tire_size_id(s.id)
                    tireModels.each do |model|
                        puts "changing #{model.id} #{model.name} from #{model.tire_size_id} to #{good_id}"
                        model.tire_size_id = good_id
                        model.save
                    end
                    s.delete
                end
            end
        end
    end
end

namespace :DeleteDuplicateTireListings do
    desc "Fix duplicate tire listings"
    task fix: :environment do
        sql = "select tire_store_id, tire_model_id, count(*) from tire_listings where is_new = true group by tire_store_id, tire_model_id having count(*) > 1 order by count(*) desc"
        bad_listings = TireListing.connection.execute(sql)
        bad_listings.each do |tl|
            all_listings = TireListing.find_all_by_tire_store_id_and_tire_model_id_and_is_new(tl["tire_store_id"], tl["tire_model_id"], true).sort{|x,y| y.updated_at <=> x.updated_at}
            @keep_listing = nil
            all_listings.each_with_index do |listing, i|
                if i != 0
                    puts "going to delete record #{listing.id} #{listing.updated_at}"

                    # update anything pointing to this listing
                    @appointments = Appointment.find_all_by_tire_listing_id(listing.id)
                    @orders = Order.find_all_by_tire_listing_id(listing.id)
                    @reservations = Reservation.find_all_by_tire_listing_id(listing.id)

                    @failed = false

                    if @appointments.size > 0
                        puts "There are #{@appointments.size} appointments to update..." 
                        @appointments.each do |a|
                            a.tire_listing_id = @keep_listing.id 
                            if !a.save 
                                @failed = true 
                            end
                        end
                    end
                    if @orders.size > 0
                        puts "There are #{@orders.size} orders to update..." 
                        @orders.each do |a|
                            a.tire_listing_id = @keep_listing.id 
                            if !a.save 
                                @failed = true 
                            end
                        end
                    end
                    if @reservations.size > 0
                        puts "There are #{@reservations.size} reservations to update..."
                        @reservations.each do |a|
                            a.tire_listing_id = @keep_listing.id 
                            if !a.save 
                                @failed = true 
                            end
                        end
                    end

                    if !@failed
                        listing.delete
                    else
                        puts "**** NOT DELETING - an update failed. ****"
                    end
                else
                    puts "not deleting record #{listing.id} #{listing.updated_at}"
                    @keep_listing = listing
                end
            end
            puts "----------------------------"
        end
    end
end

namespace :ShowMissingTireModelInfo do
    desc "Show listings that need tire model infos"
    task populate: :environment do
        arBadModels = []
        sql = "SELECT DISTINCT(tire_listings.tire_manufacturer_id), tire_listings.tire_model_id FROM tire_listings GROUP BY tire_listings.tire_manufacturer_id, tire_listings.tire_model_id ORDER BY tire_listings.tire_manufacturer_id, tire_listings.tire_model_id"
        all_listings = TireListing.connection.execute(sql)
        all_listings.each do |model|
            if model["tire_model_id"]
                m = TireModel.find(model["tire_model_id"])
                tmi = TireModelInfo.find_by_tire_manufacturer_id_and_tire_model_name(model["tire_manufacturer_id"], m.name)

                if tmi.nil? || !tmi.stock_photo1.exists?
                    # is this one in our array yet?
                    arNewBadModel = []
                    arNewBadModel << model["tire_manufacturer_id"] << m.name

                    if !arBadModels.include?(arNewBadModel)
                        arBadModels << arNewBadModel
                    end
                else
                    puts "#{tmi.photo1_thumbnail} #{model['tire_model_id']} #{m.name}"
                end
            end
        end

        arBadModels.each do |m|
            puts m
        end
    end
end

