require 'nokogiri'
require 'rest_client'

class ModelInfo < Object
    attr_accessor :manufacturer_name, :model_name, :sizestr
    attr_accessor :orig_cost, :tread_depth
    attr_accessor :load_index, :speed_rating, :rim_width, :utqg_temp, :utqg_treadwear, :utqg_traction, :sidewall

    def initialize(args)
        args.each {|k,v|
          instance_variable_set "@#{k}", v #if self.class.props.member?(k)
        } if args.is_a? Hash
    end
end

namespace :DumpTireModelInfo do
    desc "Create a file with tire data that we can load into production"
    task populate: :environment do
        File.open('TireModelInfo.json', 'w') do |info|
            # for models that we know a lot about...
            models = TireModel.where("orig_cost > 0 and tread_depth > 0").all
            models.each do |model|
               m = ModelInfo.new
               m.manufacturer_name = model.tire_manufacturer.name
               m.model_name = model.name
               m.sizestr = model.tire_size.sizestr
               m.orig_cost = model.orig_cost
               m.tread_depth = model.tread_depth
               m.load_index = model.load_index
               m.speed_rating = model.speed_rating
               m.rim_width = model.rim_width
               m.utqg_temp = model.utqg_temp
               m.utqg_traction = model.utqg_traction
               m.utqg_treadwear = model.utqg_treadwear
               m.sidewall = model.sidewall

                info.puts m.to_json
            end
        end
    end
end

namespace :LoadTireModelInfo do
    desc "Load data from a file into production"
    task populate: :environment do
        File.open('TireModelInfo.json', 'r').each_line do |s|

            p = JSON.parse(s)
            m = ModelInfo.new(p)

            manu = TireManufacturer.find_by_name(m.manufacturer_name)
            ts = TireSize.find_by_sizestr(m.sizestr)
            model = TireModel.find_by_tire_manufacturer_id_and_tire_size_id_and_name(manu.id, ts.id, m.model_name)

            #puts model.id
            #puts s
            #puts model.to_json

            begin
                if model.orig_cost.nil? or model.orig_cost == 0
                    model.orig_cost = m.orig_cost["cents"] / 100
                    model.tread_depth = m.tread_depth
                    puts model.orig_cost
                    model.save
                end
            rescue
                puts "Trouble with #{manu.name}, #{ts.sizestr}, #{m.model_name}"
            end
        end
    end
end