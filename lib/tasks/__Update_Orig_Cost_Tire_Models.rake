require 'nokogiri'
require 'rest_client'
require 'json'


class Numeric
  def roundup(nearest=10)
    self % nearest == 0 ? self : self + nearest - (self % nearest)
  end
  def rounddown(nearest=10)
    self % nearest == 0 ? self : self - (self % nearest)
  end
end 

namespace :UpdateOriginalCost do
    desc "Update Original Cost for Tire Models"
    task populate: :environment do

        i = 0
        j = 0
        price_response = ""
        TireModel.where("orig_cost is null").all.each do |model|
            begin
                price_url = "https://www.googleapis.com/shopping/search/v1/public/products?key=AIzaSyBIHrpZe5MdJM-gO5qqHarfOetZPlhCfJg&country=US&alt=json&q=" + 
                        URI::encode(model.tire_manufacturer.name + ' ' +
                                model.name + ' ' + model.tire_size.diameter.to_s + ' ' + model.tire_size.ratio.to_s + ' ' +
                                model.tire_size.wheeldiameter.to_i.to_s  + ' -used -ebay')
                j += 1
                #raise "that's enough" if j > 5

                #puts price_url

                price_response = RestClient.get price_url
                parsed_json = JSON.parse(price_response.to_s)

                #puts parsed_json
                tot_items = 0
                tot_cost = 0

                parsed_json["items"].each do |i|
                    inv = i["product"]["inventories"]
                    tot_cost += inv[0]["price"]
                    tot_items += 1
                end

                model.orig_cost = (tot_cost / tot_items).rounddown
                model.save

                puts price_url
                puts model.orig_cost

            rescue Exception => e 
                puts "We had an exception - skipping for now (" + e.message + ")."
                i += 1

                #raise "too many" if i >= 10
            end
        end
    end
end
