require 'roo'
require 'google_drive'
require 'open-uri'

def ReadData(url)
    RestClient.get url, :user_agent => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) "
    #open(url, :proxy => "http://54.243.138.45:80", "User-Agent" => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) ").read
end

namespace :FindUsedTireStores do
    desc "Find used tire stores"
    task populate: :environment do
        s = Google.new("0Aifw9NmhkY6wdDhlMm1xUy1vM3BhMGVUN2hCbmFIVHc", google_docs_username(), google_docs_password())
        row_num = 1
        (1..3).each do |i|
            f = File.open("/Users/Kevin/Google#{i}.html", 'r')
            html_search = Nokogiri::HTML(f)

            html_search.xpath("//li[@class='plcsresult']/div/div[@class='words']").each do |used_tire_store|
                begin
                    store_name = used_tire_store.xpath("h3[@class='r']").text()
                    puts "Store name: #{store_name}"
                    s.set_value(row_num, 1, store_name)

                    store_address = used_tire_store.xpath("div[@style='color:#1f1f1f;margin-top:8px']/span[1]").text()
                    puts "Store addr: #{store_address}"
                    s.set_value(row_num, 2, store_address)

                    store_phone = used_tire_store.xpath("div[@style='color:#1f1f1f;margin-top:8px']/span[2]/span").text()
                    puts "Store phone: #{store_phone}"
                    s.set_value(row_num, 3, store_phone)

                    store_website = used_tire_store.xpath("div[@class='gl']/a/@href").text()
                    puts "Store website: #{store_website}"
                    s.set_value(row_num, 4, store_website)

                    row_num += 1
                rescue
                end
            end
        end
    end
end

namespace :PutEbayTiresIntoSpreadsheet do
    desc "Put tires from eBay into google docs spreadsheet"
    task run: :environment do
        @session = GoogleDrive.login(google_docs_username(), google_docs_password())
        title = "Ebay Tires - #{Time.now.to_s(:w3c)}"

        @key = "190uUJt9DXT4MjFmzUXmC1B38g5ITGT3Brsm17NZ9omk"
        
        @spreadsheet = @session.spreadsheet_by_key(@key)        

        @worksheet = @spreadsheet.add_worksheet(title, 200, 4)
        @worksheet.title = title

        @worksheet[1, 1] = "eBay Item ID"
        @worksheet[1, 2] = "eBay Seller ID"
        @worksheet[1, 3] = "Seller Description"
        @worksheet[1, 4] = "Storefront"
        @worksheet[1, 5] = "Item Description"

        @row_count = 1

        begin
            @worksheet.save
        rescue Exception =>e
        end

        (1..50).each do |pg_num|
            sURL = "http://www.ebay.com/sch/Tires-/66471/i.html?_ipg=200&rt=nc&_pgn=#{pg_num}"
            puts "URL: #{sURL}"
            response = RestClient.get sURL
            html_listings = Nokogiri::HTML(response.to_s)
            listings = html_listings.xpath("//a[@class='vip ']")

            listings.each do |x|
                begin
                    item_url = x.attr('href')
                    response = RestClient.get item_url
                    item_id = /.*\/(.*)\?/.match(item_url)[1]

                    ##puts "#{x.attr('href')}"
                    listing_page = Nokogiri::HTML(response.to_s)
                    title_str = listing_page.xpath("//span[@class='u-dspn' and contains(@id, 'itm')]")[0].text.strip()
                    puts "title: #{title_str}"
                    seller_id = listing_page.xpath("//span[@class='mbg-nw']").text.strip()
                    puts "seller_id: #{seller_id}"

                    seller_url = listing_page.xpath("//a[contains(@href, 'http://www.ebay.com/usr/')]").attr('href').text.strip()

                    response2 = RestClient.get seller_url
                    seller_page = Nokogiri::HTML(response2.to_s)

                    seller_desc = seller_page.xpath('//h2[contains(@class,"bio")]').text.strip()
                    puts "seller_desc: #{seller_desc}"

                    bFoundStore = false
                    begin
                        if !seller_page.xpath('//span[contains(@class,"store_lk")]/a').attr('href').nil?
                            puts "Got a store"
                            bFoundStore = true
                            store_url = seller_page.xpath('//span[contains(@class,"store_lk")]/a').attr('href').text.strip()
                            #puts "store_url: #{store_url}"
                            response3 = RestClient.get store_url
                            store_page = Nokogiri::HTML(response3.to_s)

                            store_name = store_page.xpath("//h1").text.strip()
                            store_name = "Could not parse" if store_name.size == 0
                            puts "store_name: #{store_name}"
                        end
                    rescue Exception => e1 
                        # nothing
                    end

                    #store_desc = store_page.xpath("")

                    @row_count +=1
                    @worksheet[@row_count, 1] = "=HYPERLINK(" + 34.chr + item_url + 34.chr + ", " + 34.chr + item_id + 34.chr + ")"
                    @worksheet[@row_count, 2] = "=HYPERLINK(" + 34.chr + seller_url + 34.chr + ", " + 34.chr + seller_id + 34.chr + ")"
                    @worksheet[@row_count, 3] = seller_desc
                    if bFoundStore
                        @worksheet[@row_count, 4] = "=HYPERLINK(" + 34.chr + store_url + 34.chr + ", " + 34.chr + store_name + 34.chr + ")"
                    else
                        @worksheet[@row_count, 4] = "n/a"
                    end
                    @worksheet[@row_count, 5] = title_str
                    @worksheet.save

                    puts "--------------------"
                rescue Exception => e
                    puts "Exception: #{e.to_s}"
                end
            end
            #break
        end
    end
end

namespace :FindAllUsedTireStores do 
    desc "Find all used tire stores"
    task populate: :environment do
        session = GoogleDrive.login("cbkirick@gmail.com", "P@ssword!")
        worksheet_count = 0
        worksheet_part = 1

        #spreadsheet = session.spreadsheet_by_key("0Are82DpPuAZ3dElDOU1OSHhobUJUSTU1QWJaYTJhZEE")
        #spreadsheet = session.spreadsheet_by_key("0Are82DpPuAZ3dEpqT1JxYjBsSF85V0JLdk5NZ05zcUE")
        #spreadsheet = session.spreadsheet_by_key("0Are82DpPuAZ3dGJrVWFDcnJJZ3I0RFhIcW9QcjRWLVE")
        #spreadsheet = session.spreadsheet_by_key("0Are82DpPuAZ3dEo2bEZvdVRidmpvTGFLSWNHYWFYdWc")
        #spreadsheet = session.spreadsheet_by_key("0Are82DpPuAZ3dDdIWmJIN2dxbnZGN0NuRWdma1ZGZWc")
        spreadsheet = session.spreadsheet_by_key("0Are82DpPuAZ3dHVwQTRUWnNCZklKQVdSeTZUbnFIYVE")

        #["Atlanta, GA", "Athens, GA", "Gainesville, GA", "Macon, GA", "Warner Robins, GA", "Savannah, GA",
        #    "Augusta, GA", "Valdosta, GA", "Columbus, GA"].each do |city|
        
        #["Orlando, FL", "Miami, FL", "Tampa, FL", "Daytona, FL", "Fort Lauderdale, FL", "Gainesville, FL",
        #    "Jacksonville, FL", "Tallahassee, FL", "Lakeland, FL", "Ocala, FL", "Panama city, FL",
        #    "Pensacola, FL", "Sarasota, FL"].each do |city|
        #["Charlotte, NC", "Raleigh, NC", "Asheville, NC", "Winston-Salem, NC", "Durham, NC", "Greensboro, NC",
        #    "Greenville, NC", "Fayetteville, NC", "Jacksonville, NC", "Hickory, NC"].each do |city|
        #["Charleston, SC", "Greenville, SC", "Columbia, SC", "Mount Pleasant, SC", "Hilton Head, SC",
        #    "Myrtle Beach, SC"].each do |city|

        #["Nashville, TN", "Chattanooga, TN", "Knoxville, TN", "Memphis, TN", "Clarksville, TN",
        #    "Cookeville, TN", "Jackson, TN"].each do |city|
        ["Birmingham, AL", "Auburn, AL", "Huntsville, AL", "Mobile, AL", "Dothan, AL",
            "Montgomery, AL", "Tuscaloosa, AL"].each do |city|

            worksheet = spreadsheet.worksheets[worksheet_count]
            puts "Worksheet: #{worksheet_count}"
            worksheet.title = city
            worksheet.save

            worksheet[1, 1] = "Store"
            worksheet[1, 2] = "Raw Address"
            worksheet[1, 3] = "Raw Phone"
            worksheet[1, 4] = "Std Address"
            worksheet[1, 5] = "City"
            worksheet[1, 6] = "State"
            worksheet[1, 7] = "Zip"

            query = '"Used Tires" ' + city
            startURL = "http://maps.google.com/maps?q=#{URI::encode(query)}"

            search_response = ReadData startURL

            row_count = 2

            while true do
                html_search = Nokogiri::HTML(search_response.to_s)
                
                found_here = 0
                nextURL = ""
                #html_search.xpath("//div[@class='text vcard indent block']").each do |used_tire_store|
                html_search.xpath("//div[@class='text vcard indent block']").each do |used_tire_store|
                    found_here = found_here + 1
                    store_name = used_tire_store.xpath("div[@class='name lname']/span").text().strip()
                    store_addr_raw = used_tire_store.xpath("div/span[@class='pp-headline-item pp-headline-address']").text().strip()
                    store_phone_raw = used_tire_store.xpath("div/div/span[@class='pp-headline-item pp-headline-phone']/span/nobr").text().strip()
                    #puts used_tire_store.to_s
                    puts store_name
                    
                    worksheet[row_count, 1] = store_name
                    worksheet[row_count, 2] = store_addr_raw
                    worksheet[row_count, 3] = store_phone_raw

                    geo = Geocoder.search(store_addr_raw)
                    loc = geo.first
                    if !loc.nil?
                        s = loc.address_data["addressLine"]
                        worksheet[row_count, 4] = s
                        worksheet[row_count, 5] = loc.city
                        worksheet[row_count, 6] = loc.state
                        worksheet[row_count, 7] = loc.postal_code
                    end
                    worksheet.save
                    row_count += 1

                    if row_count > 500 
                        row_count = 2
                        worksheet_part += 1
                        worksheet_count = worksheet_count + 1
                        worksheet.save
                        worksheet = spreadsheet.worksheets[worksheet_count]
                        worksheet.title = "#{city}-#{worksheet_part}"
                        worksheet.save
                        worksheet[1, 1] = "Store"
                        worksheet[1, 2] = "Raw Address"
                        worksheet[1, 3] = "Raw Phone"
                        worksheet[1, 4] = "Std Address"
                        worksheet[1, 5] = "City"
                        worksheet[1, 6] = "State"
                        worksheet[1, 7] = "Zip"                        
                    end
                end

                if found_here == 0
                    puts "Nothing found at !#{nextURL}!"
                end

                nextURL = html_search.xpath("//div[@id='nn']/../@href")
                if nextURL.length == 0
                    break
                end

                search_response = ReadData("http://maps.google.com#{nextURL}")
            end
            begin
                worksheet.save
            rescue Exception => e
            end
            worksheet_count = worksheet_count + 1
        end
    end
end

namespace :FindNetDrivenCustomers do
    desc "Find NetDriven customers"
    task populate: :environment do
        # I tried using Google API but it's a PITA requiring OAuth callback,
        # and I don't feel like researching that right now.

        # let's try it with raw JSON
        (0..0).each do |rec|
            searchURL = "http://www.google.com/search?num=100&q=%22powered+by+net+driven%22&start=#{rec * 100}"
            search_response = ReadData searchURL

            html_search = Nokogiri::HTML(search_response.to_s)

            html_search.xpath("//li[@class='g']/h3/a").each do |netdriven_store|
                begin
                    netdriven = /.*q=(.*.aspx)/.match(netdriven_store.attribute('href'))
                    if netdriven 
                        netdriven_url = netdriven[1]
                        netdriven_host = URI.parse(netdriven_url).host

                        store_name = ''


#                        {["http://#{netdriven_host}/about-us/contact-us.aspx", "//div[contains(@id, 'ctr2481')]"],
#                            ["http://#{netdriven_host}/location.aspx", "//p[@class='locaddress']/strong"]}.each do |location_url, location_xpath|

                        #["http://#{netdriven_host}/about-us/contact-us.aspx",
                        #    "http://#{netdriven_host}/location.aspx", "//p[@class='locaddress']/strong"].each do |location_url|

                        #{["http://#{netdriven_host}/about-us/contact-us.aspx", "//div[contains(@id, 'ctr2481')]"],
                        #    ["http://#{netdriven_host}/location.aspx", "//p[@class='locaddress']/strong"]}.each do |location_url, location_xpath|
                        [].each do |location_url|
                            location_response = ReadData location_url
                            html_location = Nokogiri::HTML(location_response.to_s)
                            if location_response.length > 0
                                found = false
                                store_element = html_location.xpath("")
                                if store_element
                                    store_name = store_element.text().strip()
                                    if store_name != ""
                                        found = true
                                        puts "Store name: #{store_name}"
                                        store_address = html_location.xpath("//p[@class='locaddress']").text().strip().gsub(/#{store_name}/, '')
                                        puts "Store address: #{store_address}"
                                    end
                                end
                                break if found
                            end
                        end

                        if store_name != ''
                            ["http://#{netdriven_host}/tire-brands.aspx",
                                "http://#{netdriven_host}/shop-for-tires/tire-brands.aspx"].each do |brands_url|
                                brands_response = ReadData brands_url
                                html_brands = Nokogiri::HTML(brands_response.to_s)
                                if brands_response.length > 0
                                    found = false
                                    html_brands.xpath("//li/a[contains(@href, 'tire-brands/')]").each do |brand|
                                        if !found
                                            puts brands_url
                                        end
                                        found = true
                                        puts "      #{brand.text().strip()}"
                                    end
                                    break if found
                                end
                            end
                        end
                    end
                rescue
                end
            end
        end
    end
end