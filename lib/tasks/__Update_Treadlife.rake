require 'nokogiri'
require 'rest_client'

namespace :UpdateTreadlife do
    desc "Update treadlife for existing listings"
    task populate: :environment do
        # for models that we know a lot about...
        models = TireModel.where("orig_cost > 0 and tread_depth > 0").all
        puts "Total models = " + models.count.to_s
        models.each do |model|
            tot_real_tread = model.tread_depth - 2

            listings = TireListing.where("tire_model_id = ? and ((remaining_tread is null or remaining_tread = 0) or (treadlife is null or treadlife = 0))", model.id).all
            puts "Model = " + model.name + " - " + listings.count.to_s
            listings.each do |tire_listing|
                if !tire_listing.remaining_tread.nil? and tire_listing.remaining_tread > 0
                    # we have a tread...let's compute the treadlife
                    if tire_listing.remaining_tread < 3
                        tire_listing.remaining_tread = 4
                    end

                    tire_listing.treadlife = ((100 * (tire_listing.remaining_tread - 2) / tot_real_tread)).round

                    #puts "Calculated treadlife = " + tire_listing.treadlife.to_s + " (orig: #{model.tread_depth}, remaining: #{tire_listing.remaining_tread})"
                    tire_listing.save
                elsif !tire_listing.treadlife.nil? and tire_listing.treadlife > 0 
                    # we have a treadlife, let's compute the remaining tread
                    tire_listing.remaining_tread = ((tot_real_tread * tire_listing.treadlife) / 100).round + 2

                    # now recalculate the percentage
                    tire_listing.treadlife = ((100 * (tire_listing.remaining_tread - 2) / tot_real_tread)).round
                    tire_listing.save
                    ##puts "Calculated remaining_tread = " + tire_listing.remaining_tread.to_s + " (orig: #{model.tread_depth}, remaining: #{tire_listing.treadlife})"
                else
                    # we don't have either - let's create a random treadlife and set rem tread accordingly
                    puts "here"
                end

            end
        end
    end
end

