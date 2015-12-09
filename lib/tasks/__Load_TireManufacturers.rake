def ReadData(url)
    #RestClient.get url, :user_agent => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) "
    RestClient.get url, :user_agent => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) "
    p "======================="
end

namespace :CreateTireManufacturers do
    p "0000000000000000000000000"
    desc "Create tire manufacturers data"
    task populate: :environment do
        p "1212121212121212212"
        #manu_response = RestClient.get 'http://www.tirerack.com/tires/tire-brand.jsp'
        p "1111111111111111"
        # p manu_response
        tiremanufacturersurl = 'http://www.tirerack.com/tires/tire-brand.jsp'
        p "22222222222222222"
        p tiremanufacturersurl
        tire_manu_response = ReadData(tiremanufacturersurl)
        html_manu_listings = Nokogiri::HTML(tire_manu_response.to_s)
        # p "44444444444444444444"
        # p html_manu_listings
        html_manu_listings.xpath("//ul[@class='clearfix']/a").each do |tiremanu|
            p "444444444444"
            p doc = tiremanu
            p "-------------------"
            p node = doc.at_css('img')
            p "555555555555555555555"
            puts node.values.first                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
            tmp = TireManufacturer.find_or_create_by_name(tiremanu.text().strip())
            p "666666666666666666"
            p tmp
        end
    end
end