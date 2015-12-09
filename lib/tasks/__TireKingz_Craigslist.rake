require 'nokogiri'
require 'rest_client'

require 'rss'

namespace :TireKingz do
    desc "Create tirelistings for TireKingz from Craigslist data"
    task populate: :environment do
        t = TireStore.find_by_name("Tire Kingz Atlanta")

        offset = 0
        tot = 0

        feed = RSS::Parser.parse(open('http://atlanta.craigslist.org/search/sss?query=tire%20kingz&srchType=A&format=rss&s=' + offset.to_s).read, false)
        while feed.items.count > 0 do
            feed.items.each do |i|
                # puts "#{i.title} ******* #{i.description}"
                # parse out the size and the price from the title
                if i.title.include?('$') and i.title.include?('/')
                    tot = tot + 1
                    m1 = /(\d{2,})\/(\d{2,}).*?(\d{2,}).*\$(\d{2,})/.match(i.title)
                    tiresize1 = TireSize.find_or_create_by_sizestr(m1[1] + '/' + m1[2] + 'R' + m1[3])

                    l = TireListing.create(:teaser => i.title.slice(0..254), :description => i.description.slice(0..4095), :tire_store_id => t.id, 
                                              :status => 0, :price => m1[4], :treadlife => 0)
                    l.tire_size_id = tiresize1.id
                    l.source = i.link
                    l.save
                end
            end
            offset = offset + 25
            feed = RSS::Parser.parse(open('http://atlanta.craigslist.org/search/sss?query=tire%20kingz&srchType=A&format=rss&s=' + offset.to_s).read, false)
        end

        puts "Loaded " + tot.to_s + " records."
    end
end
