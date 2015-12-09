require 'nokogiri'
require 'rest_client'

require 'rss'

namespace :MergeScrapeTireStores do
    desc "Merge data from ScrapeTireStores with TireStores"
    task populate: :environment do
        TireStore.find(:all).each do |tire_store|
            if !tire_store.private_seller && tire_store.id != 13808
                matches = ScrapeTireStore.near([tire_store.latitude, tire_store.longitude], 0.05)
                if matches.size > 0
                    if tire_store.hours_not_available? && !matches.first.hours_not_available?
                        tire_store.sunday_open = matches.first.sunday_open
                        tire_store.monday_open = matches.first.monday_open
                        tire_store.tuesday_open = matches.first.tuesday_open
                        tire_store.wednesday_open = matches.first.wednesday_open
                        tire_store.thursday_open = matches.first.thursday_open
                        tire_store.friday_open = matches.first.friday_open
                        tire_store.saturday_open = matches.first.saturday_open

                        tire_store.sunday_close = matches.first.sunday_close
                        tire_store.monday_close = matches.first.monday_close
                        tire_store.tuesday_close = matches.first.tuesday_close
                        tire_store.wednesday_close = matches.first.wednesday_close
                        tire_store.thursday_close = matches.first.thursday_close
                        tire_store.friday_close = matches.first.friday_close
                        tire_store.saturday_close = matches.first.saturday_close

                        tire_store.save

                        puts "#{tire_store.name} (#{tire_store.id})"
                        puts "     #{matches.first.name}"
                        puts "   #{tire_store.hours_not_available?} #{matches.first.hours_not_available?}"
                        puts "--------------------------------------------------------------------"                                
                    end            

                    matches.first.destroy

                    #matches.each do |s|
                    #    puts "     #{s.name}"
                    #end
                else
                    #puts "*** NO MATCH"
                    if !tire_store.branding.storefront_tabs.blank? && !tire_store.hours_not_available?
                        puts "#{tire_store.id} - #{tire_store.name}"
                        puts "-------------------------------------------"
                        puts tire_store.branding.storefront_tabs
                        puts "-------------------------------------------"
                        puts tire_store.hours_open_as_string_array
                        puts "==========================================="
                        puts ""
                        puts ""
                        puts ""
                        puts ""
                    end
                end
            end
        end
    end
end

namespace :RemoveRedundantTireSizes do
    #TireModel
    #TireSearch
    #TireListing
    #AutoOption
    #GenericTireListing (tire_sizes hstore)
    #Reservation

    desc "Redundant tire sizes - fix em"
    task fix: :environment do
        TireSize.select("sizestr, count(*) as cnt").group("sizestr").having("count(*) > 1").each do |s|
            redundant = TireSize.find(:all, :conditions => ["sizestr = ?", s.sizestr], :order => "updated_at asc")

            bad_size = nil
            good_size = nil

            good_size = redundant.first

            puts "Size: #{s.sizestr}"

            model_count = 0
            search_count = 0
            listing_count = 0
            auto_option_count = 0
            reservation_count = 0
            generic_count = 0
            promotions_count = 0

            (1..redundant.size - 1).each do |i|
                bad_size = redundant[i]

                tire_models = TireModel.find_all_by_tire_size_id(bad_size.id)
                tire_searches = TireSearch.find_all_by_tire_size_id(bad_size.id)
                tire_listings = TireListing.find_all_by_tire_size_id(bad_size.id)
                auto_options = AutoOption.find_all_by_tire_size_id(bad_size.id)
                reservations = Reservation.find_all_by_tire_size_id(bad_size.id)
                generic_tire_listings = GenericTireListing.where("tire_sizes @> ('?' => ?)", bad_size.id, "tire_size_id")
                promotions = Promotion.where("tire_sizes @> ('?' => ?)", bad_size.id, "tire_size_id")

                model_count += tire_models.size
                search_count += tire_searches.count
                listing_count += tire_listings.count
                auto_option_count += auto_options.count
                reservation_count += reservations.count
                generic_count += generic_tire_listings.count
                promotions_count += promotions.count

                tire_models.each do |tm|
                    tm.tire_size_id = good_size.id 
                    tm.save 
                end

                tire_searches.each do |ts|
                    ts.tire_size_id = good_size.id
                    ts.save
                end

                tire_listings.each do |tl|
                    tl.tire_size_id = good_size.id 
                    tl.save
                end

                auto_options.each do |ao|
                    ao.tire_size_id = good_size.id 
                    ao.save
                end

                reservations.each do |r|
                    r.tire_size_id = good_size.id 
                    r.save
                end

                generic_tire_listings.each do |g|
                    g.remove_tire_size_id(bad_size.id)
                    g.add_tire_size_id(good_size.id)
                    g.save
                end

                # there are actually no promotions with sizes now...
                promotions.each do |p|
                end

                bad_size.delete
            end
            puts "Fixed #{model_count} tire models"
            puts "Fixed #{search_count} searches"
            puts "Fixed #{listing_count} listings"
            puts "Fixed #{auto_option_count} options"
            puts "Fixed #{reservation_count} reservations"
            puts "Fixed #{generic_count} generic listings"
            puts "Fixed #{promotions_count} promotions"
            puts "----------------"
        end
    end
end

namespace :FixTireSizes do
    desc "Fix the tire size data I screwed up"
    task populate: :environment do
        TireListing.find(:all).each do |l|
            m1 = /(\d{2,})\/(\d{2,})R(\d{2,})/.match(l.teaser)
            if m1
                tiresize1 = TireSize.find_or_create_by_sizestr(m1[1] + '/' + m1[2] + 'R' + m1[3])
                l.tire_size_id = tiresize1.id
                l.save

                puts "#{l.teaser} - #{tiresize1.sizestr}"
            end
        end
    end
end

namespace :FixTireModels do
    desc "Fix the tire model data I screwed up"
    task populate: :environment do
        TireListing.find(:all).each do |l|
            # find all the pertinent parts and see if they match
            begin
                if l.tire_size.sizestr != l.tire_model.tire_size.sizestr
                    puts "No match (#{l.tire_size.sizestr}, #{l.tire_model.tire_size.sizestr}, #{l.teaser}"
                    l.tire_size_id = l.tire_model.tire_size_id
                    l.save
                else
                    puts "*** MATCH ***"
                end
            rescue
                puts "Could not process #{l.id}"
            end
        end
    end
end
