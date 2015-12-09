require 'nokogiri'
require 'rest_client'

require 'rss'

namespace :JapaneseAutoCenter do
    desc "Create tirelistings for Japanese Auto Center from Craigslist data"
    task populate: :environment do
        t = TireStore.find_by_name("Japanese Auto Center")

        offset = 0
        tot = 0

        feed = RSS::Parser.parse(open('http://atlanta.craigslist.org/search/sss?query=used+tires+japanese+auto+center&srchType=A&format=rss&s=' + offset.to_s).read, false)
        while feed.items.count > 0 do
            feed.items.each do |i|
                # puts "#{i.title} ******* #{i.description}"
                # parse out the size and the price from the title
                if i.title.include?('/')
                    m1 = /(\d{2,})\/(\d{2,}).*?(\d{2,})/.match(i.title)
                    if m1.to_a.count == 4
                        tot = tot + 1
                        m1 = /(\d{2,})\/(\d{2,}).*?(\d{2,})/.match(i.title)
                        tiresize1 = TireSize.find_or_create_by_sizestr(m1[1] + '/' + m1[2] + 'R' + m1[3])

                        l = TireListing.create(:teaser => i.title.slice(0..254), :description => i.description.slice(0..4095), :tire_store_id => t.id, 
                                                  :status => 0, :price => 0, :treadlife => 0)
                        l.tire_size_id = tiresize1.id
                        l.source = i.link
                        l.save
                    end
                end
            end
            offset = offset + 25
            feed = RSS::Parser.parse(open('http://atlanta.craigslist.org/search/sss?query=used+tires+japanese+auto+center&srchType=A&format=rss&s=' + offset.to_s).read, false)
        end

        puts "Loaded " + tot.to_s + " records."
    end
end
