require 'nokogiri'
require 'rest_client'
require 'rss'

namespace :ReloadTireSizes do
    desc "Create tiresizes data for each car in the database"
    task populate: :environment do
        options = AutoOption.where("tire_size_id = 0")

        options.each do |option|
            info_response = RestClient.post 'http://server2.tiresize.biz/functions.php',
                {'xajax' => 'info2',
                    'xajaxargs' => [ option.auto_manufacturer.name, option.auto_model.name, option.auto_year.modelyear, option.name ]
                }
            xml_info_doc = Nokogiri::XML(info_response.to_s)
            xml_info_doc.xpath("//cmd[@t='txtOETireSize']").each do |tiresize|
                begin
                  # create a tiresize if we don't already have one...
                  if not tiresize.text().include?('no')
                    s = tiresize.text().slice(0, 9)

                    puts option.auto_manufacturer.name + '/' + option.auto_model.name + '/' + option.auto_year.modelyear + '/' + option.name + '---' + s

                    tiresize1 = TireSize.find_or_create_by_sizestr(s)

                    option.tire_size_id = tiresize1.id
                    option.save

                  end
                rescue
                    puts 'Could not process record.'
                end
            end
        end
    end
end
