
def haversine(lat1, long1, lat2, long2)
  dtor = Math::PI/180
  r = 6378.14*1000

  rlat1 = lat1 * dtor 
  rlong1 = long1 * dtor 
  rlat2 = lat2 * dtor 
  rlong2 = long2 * dtor 

  dlon = rlong1 - rlong2
  dlat = rlat1 - rlat2

  a = Math::sin(dlat/2) ** 2 + Math::cos(rlat1) * Math::cos(rlat2) * Math::sin(dlon/2) ** 2
  c = 2 * Math::atan2(Math::sqrt(a), Math::sqrt(1-a))
  d = r * c

  return d
end

def GetZipcodesForState(state)
    zip_url = ''
    result = []

    if !state.blank?
        # we have a state, let's hit the mashup site to get a list of zipcodes there
        zip_url = "http://gomashup.com/json.php?fds=geo/usa/zipcode/state/#{state.upcase}"

        zip_json = ''
        (1..5).each do |i|
            begin
                zip_json = ReadData(zip_url)
                break
            rescue Exception => e 
                puts "Error processing #{zip_url}: #{e.to_s} - try again"
            end
        end

        puts zip_url

        if zip_json != ''
            h = JSON.parse(zip_json.chomp(')')[1..-1])
            h["result"].each do |z|
                result << z["Zipcode"]
            end
        end
    end
    return result
end

def GetStateBoundaries(state)
    @northernmost = nil
    @southernmost = nil
    @easternmost = nil
    @westernmost = nil 

    all_zips = GetZipObjectsForState(state)

    all_zips.each do |z|
        if @northernmost.nil? || z[:latitude] > @northernmost
            @northernmost = z[:latitude] if z[:latitude] != 0.0
        end

        if @easternmost.nil? || z[:longitude] > @easternmost
            @easternmost = z[:longitude] if z[:longitude] != 0.0
        end

        if @southernmost.nil? || z[:latitude] < @southernmost
            @southernmost = z[:latitude] if z[:latitude] != 0.0
        end

        if @westernmost.nil? || z[:longitude] < @westernmost
            @westernmost = z[:longitude] if z[:longitude] != 0.0
        end
    end

    return @northernmost, @westernmost, @southernmost, @easternmost
end

def GetZipObjectsForState(state)
    zip_url = ''
    result = []

    if !state.blank?
        # we have a state, let's hit the mashup site to get a list of zipcodes there
        zip_url = "http://gomashup.com/json.php?fds=geo/usa/zipcode/state/#{state.upcase}"

        zip_json = ''
        (1..5).each do |i|
            begin
                zip_json = ReadData(zip_url)
                break
            rescue Exception => e 
                puts "Error processing #{zip_url}: #{e.to_s} - try again"
            end
        end

        puts zip_url

        if zip_json != ''
            h = JSON.parse(zip_json.chomp(')')[1..-1])
            h["result"].each do |z|
                new_zip = Hash.new
                new_zip[:latitude] = z["Latitude"].to_f
                new_zip[:longitude] = z["Longitude"].to_f
                new_zip[:zipcode] = z["Zipcode"]
                new_zip[:county] = z["County"]
                new_zip[:city] = z["City"]
                new_zip[:state] = z["State"]
                result << new_zip
            end
        end
    end
    return result
end

def us_states
[
  ['Alabama', 'AL'],
  ['Alaska', 'AK'],
  ['Arizona', 'AZ'],
  ['Arkansas', 'AR'],
  ['California', 'CA'],
  ['Colorado', 'CO'],
  ['Connecticut', 'CT'],
  ['Delaware', 'DE'],
  ['District of Columbia', 'DC'],
  ['Florida', 'FL'],
  ['Georgia', 'GA'],
  ['Hawaii', 'HI'],
  ['Idaho', 'ID'],
  ['Illinois', 'IL'],
  ['Indiana', 'IN'],
  ['Iowa', 'IA'],
  ['Kansas', 'KS'],
  ['Kentucky', 'KY'],
  ['Louisiana', 'LA'],
  ['Maine', 'ME'],
  ['Maryland', 'MD'],
  ['Massachusetts', 'MA'],
  ['Michigan', 'MI'],
  ['Minnesota', 'MN'],
  ['Mississippi', 'MS'],
  ['Missouri', 'MO'],
  ['Montana', 'MT'],
  ['Nebraska', 'NE'],
  ['Nevada', 'NV'],
  ['New Hampshire', 'NH'],
  ['New Jersey', 'NJ'],
  ['New Mexico', 'NM'],
  ['New York', 'NY'],
  ['North Carolina', 'NC'],
  ['North Dakota', 'ND'],
  ['Ohio', 'OH'],
  ['Oklahoma', 'OK'],
  ['Oregon', 'OR'],
  ['Pennsylvania', 'PA'],
  ['Puerto Rico', 'PR'],
  ['Rhode Island', 'RI'],
  ['South Carolina', 'SC'],
  ['South Dakota', 'SD'],
  ['Tennessee', 'TN'],
  ['Texas', 'TX'],
  ['Utah', 'UT'],
  ['Vermont', 'VT'],
  ['Virginia', 'VA'],
  ['Washington', 'WA'],
  ['West Virginia', 'WV'],
  ['Wisconsin', 'WI'],
  ['Wyoming', 'WY']
]
end

def GetZipcodesForState(state)
  zip_url = ''
  result = []

  if !state.blank?
    # we have a state, let's hit the mashup site to get a list of zipcodes there
    zip_url = "http://gomashup.com/json.php?fds=geo/usa/zipcode/state/#{state.upcase}"
    
    zip_json = ''
    (1..5).each do |i|
      begin
        zip_json = ReadData(zip_url)
        break
      rescue Exception => e 
        puts "Error processing #{zip_url}: #{e.to_s} - try again"
      end
    end
    
    puts zip_url

    if zip_json != ''
      h = JSON.parse(zip_json.chomp(')')[1..-1])
      h["result"].each do |z|
        result << z["Zipcode"]
      end
    end
  end
  return result
end

def ReadData(url)
    RestClient.get url, :user_agent => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) "
    #open(url, :proxy => "http://54.243.138.45:80", "User-Agent" => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) ").read
end

def PostData(url)
    RestClient.post url, :user_agent => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) "
    #open(url, :proxy => "http://54.243.138.45:80", "User-Agent" => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) ").read
end

def is_a_match?(store1, store2, distance, confidence)
  if confidence.getDistance(store1.name.downcase, store2.name.downcase) > 0.95
    return true
  elsif @distance.to_f < 0.15 &&
    (store1.name.downcase.include?("walmart") && store2.name.downcase.include?("walmart") ||
      store1.name.downcase.include?("sears") && store2.name.downcase.include?("sears") ||
      confidence.getDistance(store1.name.downcase, store2.name.downcase) > 0.85)
    return true
  elsif (distance.to_f < 0.15 &&
    confidence.getDistance(store1.name.downcase, store2.name.downcase) > 0.7 &&
    confidence.getDistance(store1.address1.downcase, store2.address1.downcase) > 0.85)
    return true 
  else
    puts "no match - name: #{confidence.getDistance(store1.name.downcase, store2.name.downcase)} addr: #{confidence.getDistance(store1.address1.downcase, store2.address1.downcase)}"
    return false
  end
end

namespace :ScrapeTireStores do

    desc "De-dupe scrape tire store data."
    task dedupe: :environment do
      @confidence = FuzzyStringMatch::JaroWinkler.create(:pure)

      @stores = ScrapeTireStore.find(:all, :order => :id)

      @match = 0
      @no_match = 0
      @none_near = 0

      @stores.each do |store|
        @nearby = ScrapeTireStore.near([store.latitude, store.longitude], 0.25)
        if @nearby.size == 1 && @nearby.first.id == store.id
          @none_near += 1
          # do nothing
        elsif @nearby.size ==2 && (@nearby.first.id == store.id || @nearby.last.id == store.id)
          puts "#{@nearby.first.name} #{@nearby.first.address1} (#{@nearby.first.id})"
          puts "#{@nearby.last.name} #{@nearby.last.address1} (#{@nearby.last.id})"
          if @nearby.first.id == store.id
            puts "Distance: #{@nearby.last.distance}"
            @distance = @nearby.last.distance
          else
            puts "Distance: #{@nearby.first.distance}"
            @distance = @nearby.first.distance
          end

          if is_a_match?(@nearby.first, @nearby.last, @distance, @confidence)
            puts "* I think we have a match *"
            if @nearby.first.google_properties.blank? && !@nearby.last.google_properties.blank?
              puts "   will use #{@nearby.last.name}"
              if @nearby.first.scraper_id != 7 && @nearby.last.scraper_id == 7
                @nearby.last.scraper_id = @nearby.first.scraper_id
                @nearby.last.store_id = @nearby.first.store_id

                if !ScrapeTireStore.find_by_scraper_id_and_store_id(@nearby.last.scraper_id, @nearby.last.store_id).nil?
                  @nearby.last.store_id += rand(1000000)
                end
                @nearby.last.save
              end
              @nearby.first.destroy
            elsif @nearby.last.google_properties.blank? && !@nearby.first.google_properties.blank?
              puts "   will use #{@nearby.first.name}"
              if @nearby.last.scraper_id != 7 && @nearby.first.scraper_id == 7
                @nearby.first.scraper_id = @nearby.last.scraper_id
                @nearby.first.store_id = @nearby.last.store_id

                if !ScrapeTireStore.find_by_scraper_id_and_store_id(@nearby.first.scraper_id, @nearby.first.store_id).nil?
                  @nearby.first.store_id += rand(1000000)
                end                
                @nearby.first.save
              end
              @nearby.last.destroy
            elsif @nearby.last.google_properties.blank? && @nearby.first.google_properties.blank?
              puts "   both are blank :("
              if @nearby.last.scraper_id == 7 && @nearby.first.scraper_id != 7
                @nearby.last.destroy
              elsif @nearby.first.scraper_id == 7 && @nearby.last.scraper_id != 7
                @nearby.first.destroy 
              else
                @nearby.last.destroy
              end
            else
              puts "   neither are blank???"
              if @nearby.first.id != @nearby.last.id 
                @nearby.last.destroy 
              end
            end
            @match += 1
          else
            puts "No match?"
            @no_match += 1
          end

          puts "-----------------------------------------------"
        elsif @nearby.size > 0
          puts "#{store.name}/#{store.address1} - #{@nearby.size}"
          got_one = false
          @nearby.each do |near|
            if near.id != store.id
              puts "      #{near.name}/#{near.address1} #{near.distance} (#{near.id})"
              if is_a_match?(store, near, near.distance, @confidence)
                got_one = true
                puts "      ^^^^^ MATCH ^^^^^"
                if store.google_properties.blank? && !near.google_properties.blank?
                  puts "   will use #{near.name}"
                  if store.scraper_id != 7 && near.scraper_id == 7
                    near.scraper_id = store.scraper_id
                    near.store_id = store.store_id

                    if !ScrapeTireStore.find_by_scraper_id_and_store_id(near.scraper_id, near.store_id).nil?
                      near.store_id += rand(1000000)
                    end
                    near.save
                  end
                  store.destroy
                  break
                elsif near.google_properties.blank? && !store.google_properties.blank?
                  puts "   will use #{store.name}"
                  if near.scraper_id != 7 && store.scraper_id == 7
                    store.scraper_id = near.scraper_id
                    store.store_id = near.store_id

                    if !ScrapeTireStore.find_by_scraper_id_and_store_id(store.scraper_id, store.store_id).nil?
                      store.store_id += rand(1000000)
                    end
                    store.save
                  end
                  near.destroy
                  break
                elsif near.google_properties.blank? && store.google_properties.blank?
                  puts "   both are blank :("
                  if near.scraper_id == 7 && store.scraper_id != 7
                    near.destroy
                    break
                  elsif store.scraper_id == 7 && near.scraper_id != 7
                    store.destroy 
                    break
                  else
                    near.destroy
                    break
                  end
                else
                  puts "   neither are blank???"
                  if store.id != near.id 
                    near.destroy 
                    break
                  end
                end
              end
            end
          end
          if got_one
            @match += 1
          else
            @no_match += 1
          end
          puts "-----------------------------------------------"
        else
          puts "#{store.name} - nope."
          @none_near += 1
          puts "-----------------------------------------------"          
        end
      end

      puts "Match: #{@match}"
      puts "No match: #{@no_match}"
      puts "None near: #{@none_near}"
    end

    desc "Move newly updated stores into Production"
    task movescrapestoproduction: :environment do
      @confidence = FuzzyStringMatch::JaroWinkler.create(:pure)

      @perfect = 0
      @close = 0
      @no_match = 0
      @bad_id = 0

      @updated_stores = ScrapeTireStore.find(:all, :conditions => ["google_properties <> ''"], :order => :id)
      @updated_stores.each do |dev_store|
        if dev_store.address1.blank? || dev_store.city.blank? || dev_store.state.blank?
          puts "Deleting #{dev_store.name}"
          dev_store.destroy
        else
          # first, search by ID
          prod_store = ProductionScrapeTireStore.find_by_id(dev_store.id)
          if prod_store.nil?
            puts "Could not find an ID match for #{dev_store.id}."
            @bad_id += 1
          else
            con_name = @confidence.getDistance(prod_store.name.downcase, dev_store.name.downcase)
            con_addr = @confidence.getDistance(prod_store.address1.downcase, dev_store.address1.downcase)
            distance_between = haversine(dev_store.latitude, dev_store.longitude, prod_store.latitude, prod_store.longitude)

            #puts "Distance: #{distance_between}"
            #puts "Con Name: #{con_name}"
            #puts "Con Addr: #{con_addr}"

            if prod_store.name.downcase == dev_store.name.downcase &&
                prod_store.address1.downcase == dev_store.address1.downcase &&
                prod_store.city.downcase == dev_store.city.downcase
                puts "Good match for #{dev_store.id}."
                @perfect += 1
            elsif distance_between < 500 &&
              con_name > 0.9 &&
              con_addr > 0.9
              puts "Close enough match for #{dev_store.id}."
              @close += 1
            else
              puts "Found a matching ID for #{dev_store.id} but no match on addr/city/st."
              puts "Distance: #{distance_between}"
              puts "Con Name: #{con_name}"
              puts "Con Addr: #{con_addr}"              
              puts "Dev: #{dev_store.name}/#{dev_store.address1}/#{dev_store.city}/#{dev_store.state}"
              puts "Prd: #{prod_store.name}/#{prod_store.address1}/#{prod_store.city}/#{prod_store.state}"
              @no_match += 1
            end
          end
        end
        puts "--------------------------------------------------"
      end

      puts "Perfect: #{@perfect}"
      puts "Close: #{@close}"
      puts "None: #{@no_match}"
      puts "No ID: #{@bad_id}"
    end

    desc "Scrape UsedTireNetwork.net for tire stores"
    task usedtirenetwork: :environment do

      counter = 0
      max_process = 9999999

      all_stores = []

      @session = GoogleDrive.login(google_docs_username(), google_docs_password())
      title = "Used Tire Network - #{Time.now.to_s(:w3c)}"

      @key = "1QwEasD6-W8F8irR5x9i276sFrQ6MWEmsP-rJJL5mgIw"
      
      @spreadsheet = @session.spreadsheet_by_key(@key)        

      @worksheet = @spreadsheet.add_worksheet(title, 200, 4)
      @worksheet.title = title

      @worksheet[1, 1] = "Store Name"
      @worksheet[1, 2] = "Address 1"
      @worksheet[1, 3] = "Address 2"
      @worksheet[1, 4] = "City/ST/Zip"
      @worksheet[1, 5] = "Phone"
      @worksheet[1, 6] = "Website"

      @row_count = 1

      begin
          @worksheet.save
      rescue Exception =>e
      end      

      us_states.each do |arr|
        if counter > max_process
          break
        end

        if !arr[1].blank?
          zip_codes = GetZipcodesForState(arr[1])
          zip_codes.each do |zip|
            if counter > max_process
              break
            end

            utn_URL = "http://usedtirenetwork.net/locator?distance%5Bpostal_code%5D=#{zip}&distance%5Bsearch_distance%5D=999&distance%5Bsearch_units%5D=mile"
            utn_html = ""
            (1..5).each do |i|
                begin
                    utn_html = ReadData(utn_URL)
                    break
                rescue Exception => e 
                    puts "Error processing #{utn_URL}: #{e.to_s} - try again"
                end
            end
            if utn_html != '' # there was no error
                utn_data = Nokogiri::HTML(utn_html.to_s)
                
                utn_data.xpath("//tr[contains(@class, 'odd') or contains(@class, 'even')]").each do |store_div|
                  #puts store_div.to_s

                  store_name = store_div.xpath("./td[2]/strong/a/.").text.strip()
                  #puts store_name
                  all_addr = store_div.xpath("./td[2]").text.strip().split("\n")
                  store_addr1 = all_addr[1]
                  #puts store_addr1

                  if all_addr.size > 4
                    store_addr2 = all_addr[2]
                    store_city_st_zip = all_addr[3]
                  else
                    store_addr2 = ""
                    store_city_st_zip = all_addr[2]
                  end
                  #puts store_addr2
                  #puts store_city_st_zip
                  all_phone = store_div.xpath("./td[3]").text.strip().split("\n")
                  store_phone = all_phone[0]
                  #puts store_phone

                  store_website = store_div.xpath("./td[2]/div[@class='links']/a[.='View Website']")
                  if store_website
                    store_website = store_website.text.strip()
                  else
                    store_website = ""
                  end

                  if all_stores.detect {|store| store["store_addr1"] == store_addr1 && store["city_st_zip"] == store_city_st_zip}.nil?
                    new_store = {}
                    new_store["store_name"] = store_name
                    new_store["store_addr1"] = store_addr1
                    new_store["store_addr2"] = store_addr2
                    new_store["city_st_zip"] = store_city_st_zip
                    new_store["phone"] = store_phone
                    new_store["website"] = store_website

                    puts store_name
                    puts store_addr1
                    puts store_addr2
                    puts store_city_st_zip
                    puts store_phone
                    puts store_website
                    puts "------------"

                    @row_count +=1
                    @worksheet[@row_count, 1] = store_name
                    @worksheet[@row_count, 2] = store_addr1
                    @worksheet[@row_count, 3] = store_addr2
                    @worksheet[@row_count, 4] = store_city_st_zip
                    @worksheet[@row_count, 5] = store_phone
                    @worksheet[@row_count, 6] = store_website
                    begin
                      @worksheet.save
                    rescue
                    end

                    all_stores << new_store

                    counter += 1
                    if counter > max_process
                      break
                    end
                  else
                    #puts "skipping duplicate..."
                  end
                  #puts "--------------"
                end            
            end         
          end
        end
      end      
    end

    desc "Scrape Sears.com for tire stores"
    task sears: :environment do
      scraper_id = 1
      
      JSONUrl = "http://www.sears.com/shc/s/StoreLocatorSearch?storeId=10153&latitude=34.4762579&longitude=-83.85790529999997&distance=50000&sourcePage=storeLocator&shcAJAX=1"
      
      sears_json = ''
      (1..5).each do |i|
          begin
              sears_json = ReadData(JSONUrl)
              break
          rescue Exception => e 
              puts "Error processing #{JSONUrl}: #{e.to_s} - try again"
          end
      end
      if sears_json != '' # there was no error
        h = JSON.parse(sears_json)
        h["result"].each do |r|
          if r['storeName'] == "Sears_Auto_Centers"
            s = ScrapeTireStore.find_by_scraper_id_and_store_id(scraper_id, r['unitno'])
            if !s.nil?
              puts "Updating #{r['name']} #{r['city']} #{r['stat']}"
            else
              puts "Adding #{r['name']} #{r['city']} #{r['stat']}"
              s = ScrapeTireStore.new 
            end
            s.name = r['name']
            s.store_id = r['unitno']
            s.address1 = r['address']
            s.city = r['city']
            s.state = r['stat']
            s.zipcode = r['zip']
            s.phone = r['phone1']
            s.scraper_id = scraper_id
            s.save
            
            if s.latitude.nil? || s.latitude.to_i == 0
              s.destroy
            end
          end
        end
      end      
    end
    
    
    desc "Scrape Walmart.com for tire stores"
    task walmart: :environment do
      scraper_id = 2
      
      counter = 0
      max_process = 999999999
      
      ZIPUrl = ''

      us_states.each do |arr|
        if counter > max_process
          break
        end
        if !arr[1].blank?
          # we have a state, let's hit the mashup site to get a list of zipcodes there
          ZIPUrl = "http://gomashup.com/json.php?fds=geo/usa/zipcode/state/#{arr[1]}"
          
          zip_json = ''
          (1..5).each do |i|
            begin
              zip_json = ReadData(ZIPUrl)
              break
            rescue Exception => e 
              puts "Error processing #{ZIPUrl}: #{e.to_s} - try again"
            end
          end
              
          if zip_json != ''
            h = JSON.parse(zip_json.chomp(')')[1..-1])
            h["result"].each do |z|
              zipcode = z["Zipcode"]
              resultsURL = "http://www.walmart.com/storeLocator/ca_storefinder_results.do?serviceName=&rx_title=com.wm.www.apps.storelocator.page.serviceLink.title.default&rx_dest=%2Findex.gsp&sfrecords=50&sfsearch_single_line_address=#{zipcode}&sfatt=TIRE_AND_LUBE"              
              results_html = ''
              
              (1..5).each do |i|
                begin
                  results_html = ReadData(resultsURL)
                  break
                rescue Exception => e
                  puts "Error processing #{resultsURL}: #{e.to_s} - try again"
                end
              end
              
              counter += 1
              if counter > max_process
                break
              end
              if results_html != ''
                
                results_data = Nokogiri::HTML(results_html.to_s)
                
                results_data.xpath("//div[@class='storeDescription']").each do |store_div|
                  store_name = store_div.xpath("h3/a").text().strip
                  store_id = /.*#(\d*)/.match(store_name)[1]
                  store_addr = store_div.xpath("div[2]").text().strip()
                  store_city_st_zip = store_div.xpath("div[3]").text().strip()
                  store_phone = store_div.xpath("div[4]").text().strip().gsub(/Phone:\ /, "").delete("^0-9")
                  ar = /^(.+)[,\\s]+(.+?)\s*(\d{5})?$/.match(store_city_st_zip)
                  store_city = ar[1].strip()
                  store_state = ar[2].strip()
                  store_zip = ar[3].strip()
                  
                  s = ScrapeTireStore.find_by_scraper_id_and_store_id(scraper_id, store_id)
                  if !s.nil?
                    puts "Skipping #{store_name} #{store_city} #{store_state}"
                  else
                    puts "Adding #{store_name} #{store_city} #{store_state}"
                    s = ScrapeTireStore.new 
                  
                    s.name = store_name
                    s.store_id = store_id
                    s.address1 = store_addr
                    s.city = store_city
                    s.state = store_state
                    s.zipcode = store_zip
                    s.phone = store_phone
                    s.scraper_id = scraper_id
                    s.save
            
                    if s.latitude.nil? || s.latitude.to_i == 0
                      s.destroy
                    end
                  end
                end
              end
            end
            
            if counter > max_process
              break
            end
          end
        end
      end
    end
    
    
    desc "Scrape Goodyear.com for tire stores"
    task goodyear: :environment do
      scraper_id = 3
      
      counter = 0
      max_process = 9999999

      us_states.each do |arr|
        if counter > max_process
          break
        end
        if !arr[1].blank?
          # we have a state, let's hit the Goodyear site to find a list of cities
          StateURL = "http://www.goodyear.com/en-US/services/#{arr[1]}/tire-stores"
          
          state_html = ''
          (1..5).each do |i|
            begin
              state_html = ReadData(StateURL)
              break
            rescue Exception => e 
              puts "Error processing #{StateURL}: #{e.to_s} - try again"
            end
          end
              
          if state_html != ''
            state_data = Nokogiri::HTML(state_html.to_s)
            state_data.xpath("//div[@class='cities-list']/ul/li/a").each do |c|
              CityURL = "http://www.goodyear.com/" + c.attribute("href").text().strip()
              
              city_html = ''
              (1..5).each do |i|
                begin
                  city_html = ReadData(CityURL)
                  break
                rescue Exception => e
                  puts "Error processing #{CityURL}: #{e.to_s} - try again"
                end
              end
              
              puts "---------------------------------------------------"
              puts CityURL
              puts "---------------------------------------------------"              
              
              counter += 1
              if counter > max_process
                break
              end
              if city_html != ''
                city_data = Nokogiri::HTML(city_html.to_s)
                city_data.xpath("//div[@class='all-stores']/table//tr").each do |store_row|
                  if store_row.xpath("th").size == 0
                    data_cells = store_row.xpath("td")
                    
                    begin
                      #puts "#{data_cells}"
                      store_name = data_cells[0].text().strip()
                      store_full_addr = data_cells[1]
                      store_full_arr = store_full_addr.to_s.split("<br>")
                      store_addr = store_full_arr[0].strip().gsub(/\t/, '').gsub(/\r\n/, ' ').sub!("<td> ", "").strip()
                      store_city_state_zip = store_full_arr[1].strip().gsub(/\t/, '').gsub(/\r\n/, ' ').chomp(" </td>").strip()

                      ar = /^(.+)[,\\s]+(.+?)\s*(\d{5})?$/.match(store_city_state_zip)
                      store_city = ar[1].strip()
                      store_state = ar[2].strip()
                      store_zip = ar[3].strip()
                    
                      store_phone = data_cells[2].text().strip().delete("^0-9")
                      
                      store_id = store_phone.to_s[3..10]

                      s = ScrapeTireStore.find_by_scraper_id_and_store_id(scraper_id, store_id)
                      if !s.nil?
                        puts "Skipping #{store_name} #{store_city} #{store_state}"
                      else
                        puts "Adding #{store_name} #{store_city} #{store_state}"
                        s = ScrapeTireStore.new 
                  
                        s.name = store_name
                        s.store_id = store_id
                        s.address1 = store_addr
                        s.city = store_city
                        s.state = store_state
                        s.zipcode = store_zip
                        s.phone = store_phone
                        s.scraper_id = scraper_id
                        s.save
            
                        if s.latitude.nil? || s.latitude.to_i == 0
                          s.destroy
                        elsif ScrapeTireStore.find_all_by_latitude_and_longitude(s.latitude, s.longitude).size > 1
                          puts "Destroying duplicate #{s.name} #{s.address1} #{s.city} #{s.state}"
                          s.destroy
                        end
                      end                      
                    
                      #puts "Name:  #{store_name}"
                      #puts "Addr:  #{store_addr}"
                      #puts "City:  #{store_city}"
                      #puts "State: #{store_state}"
                      #puts "Zip:   #{store_zip}"
                      #puts "Phon:  #{store_phone}"
                      #puts "-----"
                    rescue Exception => e
                      # some data issue, ignore and move on 
                      puts "Exception: #{e.to_s}"
                    end
                  end
                end
              end
            end
            
            if counter > max_process
              break
            end
          end
        end
      end
    end
    
    
    desc "Scrape Bridgestone for tire stores"
    task bridgestone: :environment do
      scraper_id = 4
      
      counter = 0
      max_process = 999999999
      
      ZIPUrl = ""

      us_states.each do |arr|
        if counter > max_process
          break
        end
        if !arr[1].blank?
          # we have a state, let's hit the mashup site to get a list of zipcodes there
          ZIPUrl = "http://gomashup.com/json.php?fds=geo/usa/zipcode/state/#{arr[1]}"
          
          zip_json = ''
          (1..5).each do |i|
            begin
              zip_json = ReadData(ZIPUrl)
              break
            rescue Exception => e 
              puts "Error processing #{ZIPUrl}: #{e.to_s} - try again"
            end
          end
              
          if zip_json != ''
            h = JSON.parse(zip_json.chomp(')')[1..-1])
            h["result"].each do |z|
              zipcode = z["Zipcode"]
              
              puts "========================================="
              puts "Processing: #{zipcode} (#{arr[1]})"
              puts "========================================="
              
              resultsURL = "http://www.bsro.com/locate/displayMap.action?zip=#{zipcode}"
              results_html = ''
              
              (1..5).each do |i|
                begin
                  results_html = ReadData(resultsURL)
                  break
                rescue Exception => e
                  puts "Error processing #{resultsURL}: #{e.to_s} - try again"
                end
              end
              
              counter += 1
              if counter > max_process
                break
              end
              if results_html != ''
                storeREGEX = /.*var\ storedata\ \=\ \[(.*)\].*/.match(results_html.to_s)
                
                if storeREGEX.nil? || storeREGEX.size < 2
                  puts "Didn't find store data on #{resultsURL}"
                else
                  storesJSON = '{"results":[' + storeREGEX[1].gsub(/'/, '"') + ']}'
                  h = JSON.parse(storesJSON)
                  h["results"].each do |r|
                    store_name = r["name"]
                    store_id = r["num"]
                    store_addr = r["add1"]
                    store_city_st_zip = r["add2"]
                    store_phone = r["phone"].delete("^0-9")
                  
                    #puts store_city_st_zip
                  
                    ar = /^(.+)[,\\s]+(.+?)\s*(\d{5}).*$/.match(store_city_st_zip)
                    store_city = ar[1].strip()
                    store_state = ar[2].strip()
                    store_zip = ar[3].strip()
                  
                    s = ScrapeTireStore.find_by_scraper_id_and_store_id(scraper_id, store_id)
                    if !s.nil?
                      puts "Skipping #{store_name} #{store_city} #{store_state}"
                    else
                      puts "Adding #{store_name} #{store_city} #{store_state}"
                      s = ScrapeTireStore.new 
                  
                      s.name = store_name
                      s.store_id = store_id
                      s.address1 = store_addr
                      s.city = store_city
                      s.state = store_state
                      s.zipcode = store_zip
                      s.phone = store_phone
                      s.scraper_id = scraper_id
                      s.save
            
                      if s.latitude.nil? || s.latitude.to_i == 0
                        s.destroy
                      elsif ScrapeTireStore.find_all_by_latitude_and_longitude(s.latitude, s.longitude).size > 1
                        puts "Destroying duplicate #{s.name} #{s.address1} #{s.city} #{s.state}"
                        s.destroy
                      end
                    end
                  end
                end
              end
            end
            
            if counter > max_process
              break
            end
          end
        end
      end
    end
    
    
    desc "Scrape Continental for tire stores"
    task continental: :environment do
      scraper_id = 5
      
      counter = 0
      max_process = 10
      
      StoresURL = "http://www.contilink.com/jsp/storefront/plt.do?method=findByCityState&division=PLT&brand=C&country=US&search=true&city=kansas+city&state=MO&radius=3000#null"
      stores_response = ''
      (1..5).each do |i|
          begin
              stores_response = ReadData(StoresURL)
              break
          rescue Exception => e 
              puts "Error processing #{StoresURL}: #{e.to_s} - try again"
          end
      end
      if stores_response != '' # there was no error
          stores_data = Nokogiri::HTML(stores_response.to_s)
          
#          puts stores_response.to_s

          stores = stores_data.xpath("//table[@width='471']/tr")
          
          # first is auto shops
          stores.xpath("td")[0].xpath("table/tr").each do |store|
            #puts "--------"
            #puts store.to_s
            #puts "--------"
            
            store_name = store.xpath("td/b/a[@class='c2s12b-a']").text().strip()
            store_all = store.xpath(".//p[@class='location']").text().strip().sub!("Get Directions", "").gsub(/        /, "")
            store_link = store.xpath(".//strong/a[@class='c2s12-a']/@href").text().strip()
            store_id = /.*storefront=(\d*)/.match(store_link)[1]
            ar_data = store_all.split("\r")
            
            if ar_data.size == 6
              store_addr = ar_data[1][1..100]
              store_city_st_zip = ar_data[3]
              store_phone = ar_data[5].delete("^0-9")
              ar_city = /^(.+)[,\\s]+(.+?)\s*(\d{5}).*$/.match(store_city_st_zip)
              begin
                store_city = ar_city[1].strip()
                store_state = ar_city[2].strip()
                store_zip = ar_city[3].strip()
                
                s = ScrapeTireStore.find_by_scraper_id_and_store_id(scraper_id, store_id)
                if !s.nil?
                  puts "Skipping #{store_name} #{store_city} #{store_state}"
                else
                  puts "Adding #{store_name}, #{store_addr}, #{store_city} #{store_state} #{store_zip}"
                  s = ScrapeTireStore.new 
              
                  s.name = store_name
                  s.store_id = store_id
                  s.address1 = store_addr
                  s.city = store_city
                  s.state = store_state
                  s.zipcode = store_zip
                  s.phone = store_phone
                  s.scraper_id = scraper_id
                  s.save
        
                  if s.latitude.nil? || s.latitude.to_i == 0
                    puts "Ooops, geocode failed."
                    s.destroy
                  elsif ScrapeTireStore.find_all_by_latitude_and_longitude(s.latitude, s.longitude).size > 1
                    puts "Destroying duplicate #{s.name} #{s.address1} #{s.city} #{s.state}"
                    s.destroy
                  end
                end
              
                #puts "#{store_name}"
                #puts "#{store_city}"
                #puts "#{store_state}"
                #puts "#{store_zip}"
                #puts "#{store_phone}"
                #puts store_id
                #puts "=================="
              rescue Exception => e
                #puts "*************"
                #puts e.to_s
                #puts "*************"
              end
            end
          end
      end
    end
    
    
    desc "Scrape Yokohama for tire stores"
    task yokohama: :environment do
      scraper_id = 6
      
      counter = 0
      max_process = 999999999
      
      ZIPUrl = ""

      us_states.each do |arr|
        if counter > max_process
          break
        end
        if !arr[1].blank?
          # we have a state, let's hit the mashup site to get a list of zipcodes there
          ZIPUrl = "http://gomashup.com/json.php?fds=geo/usa/zipcode/state/#{arr[1]}"
          
          zip_json = ''
          (1..5).each do |i|
            begin
              zip_json = ReadData(ZIPUrl)
              break
            rescue Exception => e 
              puts "Error processing #{ZIPUrl}: #{e.to_s} - try again"
            end
          end
              
          if zip_json != ''
            h = JSON.parse(zip_json.chomp(')')[1..-1])
            h["result"].each do |z|
              zipcode = z["Zipcode"]
              
              puts "========================================="
              puts "Processing: #{zipcode} (#{arr[1]})"
              puts "========================================="
              
              resultsURL = "http://www.yokohamatire.com/dealer_search/lookup_new?location=#{zipcode}&radius=100&commercial=0&dealer=tire&promo="
              results_html = ''
              
              (1..5).each do |i|
                begin
                  results_html = PostData(resultsURL)
                  # testing the string to make sure it's parseable
                  h = JSON.parse(results_html)
                  break
                rescue Exception => e
                  results_html = ""
                  puts "Error processing #{resultsURL}: #{e.to_s} - try again"
                end
              end
              
              if results_html == ""
                break
              end

              h = JSON.parse(results_html)
              
              if h["results"].nil?
                break
              end

              h["results"].each do |r|
                counter += 1
                if counter > max_process
                  break
                end
                
                store_name = r["name"]
                store_addr = r["address"]
                store_city = r["city"]
                store_phone = r["phone"].delete("^0-9")
                store_id = store_phone.to_s[3..10]                
                store_state = r["state"]
                store_zip = r["zip"]
              
                s = ScrapeTireStore.find_by_scraper_id_and_store_id(scraper_id, store_id)
                if !s.nil?
                  puts "Skipping #{store_name} #{store_city} #{store_state}"
                else
                  puts "Adding #{store_name} #{store_city} #{store_state}"
                  s = ScrapeTireStore.new 
              
                  s.name = store_name
                  s.store_id = store_id
                  s.address1 = store_addr
                  s.city = store_city
                  s.state = store_state
                  s.zipcode = store_zip
                  s.phone = store_phone
                  s.scraper_id = scraper_id
                  s.save
        
                  if s.latitude.nil? || s.latitude.to_i == 0
                    s.destroy
                  elsif ScrapeTireStore.find_all_by_latitude_and_longitude(s.latitude, s.longitude).size > 1
                    puts "Destroying duplicate #{s.name} #{s.address1} #{s.city} #{s.state}"
                    s.destroy
                  end
                end
              end
            end
            
            if counter > max_process
              break
            end
          end
        end
      end
    end

    desc "Use Google Places API to find tire stores"
    task google_places: :environment do
        @count = 0
        @already_has_google_id = 0
        @found_direct_match = 0
        @found_close_match = 0
        @woulda_created = 0

        us_states().each do |cur_state|
        #[["Georgia", "GA"]].each do |cur_state|
            if !["GA"].include?(cur_state[1])

                puts "**********************************************"
                puts "PROCESSING #{cur_state[1]}"
                puts "**********************************************"

                @current_state = cur_state[1]
                @northernmost, @westernmost, @southernmost, @easternmost = GetStateBoundaries(@current_state)

                if false
                    @southernmost = @northernmost
                    @easternmost = @westernmost
                end

                @degrees_per_mile = (1.0 / 69.0)

                @degrees_per_twenty_miles = 20.0 * @degrees_per_mile

                if false
                    # hard code to atlanta
                    @northernmost = 33.7550 + (2.0 * @degrees_per_twenty_miles)
                    @southernmost = 33.7550 - (2.0 * @degrees_per_twenty_miles)
                    @easternmost = -84.3900 + (2.0 * @degrees_per_twenty_miles)
                    @westernmost = -84.3900 - (2.0 * @degrees_per_twenty_miles)
                end

                @confidence = FuzzyStringMatch::JaroWinkler.create(:pure)
                # treadhunter.mailer
                #@client = GooglePlaces::Client.new("AIzaSyBQwN5ElfWU1cm0KPcmipn-oxBwQ6Fhtao")

                # cbkirick
                @client = GooglePlaces::Client.new(google_places_api_key)
                @next_page_token = ""
                @save_tire_store = true

                @exception_count = 0

                (@westernmost..@easternmost).step(@degrees_per_twenty_miles).each do |lon|
                    (@southernmost..@northernmost).step(@degrees_per_twenty_miles).each do |lat|
                        puts "Processing lat/long: #{lat}, #{lon}"
                        @page_no = 1
                        @done_with_this = false                
                        while @done_with_this == false do
                            if @next_page_token.blank?
                                puts "Running new query because no next page token."
                                begin
                                    @places = @client.spots(lat, lon, :radius => 40000, :keyword => "tire store")
                                rescue Exception => e
                                    puts "Query failed. (#{lat}, #{lon}) - #{e.to_s}"
                                    @places = []
                                end
                            else
                                puts "Using next page token...#{@next_page_token}"
                                begin
                                    @places = @client.spots_by_pagetoken(@next_page_token, :radius => 40000)
                                rescue Exception => e
                                    puts "Query failed. (#{lat}, #{lon}) - #{e.to_s}"
                                    @places = []
                                end
                            end

                            if @places.size == 0
                                @done_with_this = true
                                @next_page_token = ""
                            else
                                @next_page_token = @places.last.nextpagetoken
                                if @next_page_token.blank?
                                    puts "next page token is blank..."
                                end
                                if @next_page_token.blank?
                                    @done_with_this = true
                                end
                            end

                            puts "*******************************************"
                            puts "Processing page #{@page_no} #{(@places.size)}"
                            puts "*******************************************"
                            @page_no += 1

                            if @places.nil?
                                @places = []
                            end

                            @places.each do |tire_store|
                                # have we already processed this one?
                                if !ScrapeTireStore.find_by_google_place_id(tire_store.id).nil?
                                    puts "-------------------------------------"
                                    puts "Skipping #{tire_store.name} because it's already in the DB with a Google ID"
                                    puts "-------------------------------------"
                                    @already_has_google_id += 1
                                    next
                                end

                                puts "-------------------------------------"
                                puts "Searching for an existing tire_store at #{tire_store.lat}, #{tire_store.lng}"
                                puts tire_store.name

                                # do we already have something at this location?
                                existing_tire_store = ScrapeTireStore.find_by_latitude_and_longitude(tire_store.lat, tire_store.lng)
                                begin
                                    c = @client.spot(tire_store.reference)

                                    #########################################################
                                    #if !tire_store.photos.nil? && tire_store.photos.size > 0
                                    #    puts "logo: " + tire_store.photos[0].fetch_url(800)
                                    #end
                                    #########################################################

                                    if !existing_tire_store.nil?
                                        puts "Found one!"

                                        @found_direct_match += 1

                                        @count += 1
                                        existing_tire_store.set_fields_from_google_place(c)
                                        if @save_tire_store
                                            existing_tire_store.save
                                        end
                                    else
                                        # we don't have an entry with this lat/long.  Let's do a couple more checks
                                        # to make sure it's a new one.
                                        puts "Did not find..."
                                        if false && c.region != @current_state
                                            puts "skipping - wrong state (#{c.region} != #{@current_state}"
                                        else
                                            # let's do another check at this address...
                                            if false
                                                ar = c.formatted_address.split(",")
                                                search_address = ar[0].strip
                                                search_city = ar[1].strip
                                                search_state = ar[2].strip
                                            else
                                                search_address = "#{c.street_number} #{c.street}"
                                                search_city = c.city
                                                search_state = c.region

                                                if search_address.nil? || search_city.nil? || search_state.nil?
                                                    ar = c.formatted_address.split(",")
                                                    begin
                                                        search_address = ar[0].strip
                                                        search_city = ar[1].strip
                                                        search_state = ar[2].strip
                                                    rescue
                                                        search_address = ""
                                                        search_city = ""
                                                        search_state = ""
                                                    end
                                                end
                                            end

                                            existing_tire_store = ScrapeTireStore.find(:first, :conditions => ["lower(name) = ? and lower(address1) = ? and lower(city) = ? and lower(state) = ?", tire_store.name.downcase, search_address.downcase, search_city.downcase, search_state.downcase])

                                            if existing_tire_store.nil?
                                                puts "Still could not find."

                                                close_tire_stores = FuzzyMatch.new(ScrapeTireStore.near("#{search_address}, #{search_city}, #{search_state}", 0.25), :read => :name)
                                                best_guess = close_tire_stores.find(tire_store.name)
                                                if best_guess
                                                    # check our confidence score
                                                    con = @confidence.getDistance(best_guess.name.downcase, tire_store.name.downcase)
                                                    if con < 0.9
                                                        puts "I have one nearby but not a good match"
                                                        puts "Looking for: #{tire_store.name} #{search_address}, #{search_city} #{search_state}"
                                                        puts "Found: #{best_guess.name} #{best_guess.address1}, #{best_guess.city} #{best_guess.state}"
                                                        @count += 1
                                                        @woulda_created += 1


                                                        if c.name.downcase.include?("tire")
                                                          new_tire_store = ScrapeTireStore.new
                                                          new_tire_store.scraper_id = 7
                                                          new_tire_store.set_fields_from_google_place(c)
                                                          if @save_tire_store
                                                              new_tire_store.save
                                                          end
                                                        end
                                                        puts "-------------------------------------"
                                                    else
                                                        puts "I think I found a match:"
                                                        puts "Looking for: #{tire_store.name} #{search_address}, #{search_city} #{search_state}"
                                                        puts "Found: #{best_guess.name} #{best_guess.address1}, #{best_guess.city} #{best_guess.state}"

                                                        @count += 1
                                                        @found_close_match += 1
                                                        best_guess.set_fields_from_google_place(c)
                                                        if @save_tire_store
                                                            best_guess.save
                                                        end
                                                    end
                                                else
                                                    puts "I really don't think I have this one...#{c.reference}"
                                                    puts "#{search_address}, #{search_city} #{search_state}"
                                                    @count += 1
                                                    @woulda_created += 1

                                                    if c.name.downcase.include?("tire")
                                                      new_tire_store = ScrapeTireStore.new 
                                                      new_tire_store.scraper_id = 7
                                                      new_tire_store.set_fields_from_google_place(c)
                                                      if @save_tire_store
                                                          new_tire_store.save
                                                      end
                                                    end
                                                    puts "-------------------------------------"                                    
                                                end
                                            else
                                                puts "Yep, I got it this time!"
                                                @count += 1
                                                @found_direct_match += 1
                                                existing_tire_store.set_fields_from_google_place(c)
                                                if @save_tire_store
                                                    existing_tire_store.save
                                                end                                    
                                                puts "-------------------------------------"
                                            end
                                        end
                                    end
                                rescue Exception => e
                                    if e.to_s != "GooglePlaces::NotFoundError"
                                        # I'll allow up to 10 failures
                                        e.backtrace.each do |msg|
                                            puts msg
                                        end
                                        puts "Failure #{@exception_count} - #{e.to_s}"
                                        @exception_count += 1

                                        if @exception_count > 10
                                            puts "I've had 10 failures.  I give up."
                                            puts "Processed #{@count}"
                                            return
                                        end
                                    else
                                        puts "-------------------------------------"
                                        puts "Got a GooglePlaces::NotFoundError error.  Ignoring."
                                        puts "-------------------------------------"
                                    end
                                end
                            end
                        end
                    end
                end
            else
                puts "**********************************************"
                puts "Skipping #{cur_state[1]} - already processed."
                puts "**********************************************"
            end
        end

        puts "Processed #{@count}"
        puts "Already had Google ID: #{@already_has_google_id}"
        puts "Direct match found: #{@found_direct_match}"
        puts "Found close match: #{@found_close_match}"
        puts "Would have created new: #{@woulda_created}"
    end


end