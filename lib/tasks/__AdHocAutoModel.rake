require 'nokogiri'
require 'open-uri'

namespace :AdHocVehicle do
    desc "Create vehicle model data by hand"
    task populate: :environment do
        auto_maker_str = "BMW"
        auto_model_str = "323c"
        auto_year_str = "2000"
        auto_options_str = "Sport Package"
        size_str = "225/45R17"

        auto_manu = AutoManufacturer.find_by_name(auto_maker_str)
        if !auto_manu
            raise "Could not find #{auto_maker_str}"
        end

        auto_model = AutoModel.find_or_create_by_auto_manufacturer_id_and_name(auto_manu.id, auto_model_str)
        auto_year = AutoYear.find_or_create_by_modelyear_and_auto_model_id(auto_year_str, auto_model.id)
        tire_size = TireSize.find_or_create_by_sizestr(size_str)
        auto_option = AutoOption.find_or_create_by_auto_year_id_and_name_and_tire_size_id(auto_year.id, auto_options_str, tire_size.id)
    end
end