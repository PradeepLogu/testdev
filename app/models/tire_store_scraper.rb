class TireStoreScraper 
    include ActiveModel::Validations

    attr_accessor :email
    attr_accessor :password
    attr_accessor :cities
    attr_accessor :state
    attr_accessor :city_array
    attr_accessor :key
    attr_accessor :success
    attr_accessor :new_format
    attr_accessor :keywords

    attr_accessor :session
    attr_accessor :spreadsheet
    attr_accessor :worksheet

    attr_accessor :row_count
    
    attr_accessor :google_url, :yp_url

    validates_presence_of :email, :password, :cities, :state, :key
    validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i

	  def ReadData(url)
        result = nil
        (1..10).each do |i|
            begin
                result = RestClient.get url, :user_agent => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) "
                break
            rescue Exception => e
                # just going to try again
                result = nil
                sleep 5
            end
        end        
    	#open(url, :proxy => "http://54.243.138.45:80", "User-Agent" => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) ").read
        return result
    end	

    def initialize(attributes = {})
        unless attributes.nil?
            attributes.each do |name, value|
                send("#{name}=", value)
            end
        end
    end 

    def to_key
    end
    
    def YPKeywords
      keywords.gsub(/\"/, '').gsub(/\'/, '')
    end

    def scrape_yp
        result = []
        err_count = 0

        puts "Starting to process YP"

        @city_array.each do |c|
            city = "#{c}-#{@state}"
            puts "Processing YP #{city}"

            #row_count = @worksheet.num_rows
            #puts "#{row_count} rows found"

            rec_count = 0

            (1..99).each do |i|
                #tirestoresurl = "http://www.yellowpages.com/" + URI::encode(city.downcase) + "/used-tire-dealers?page=#{i}&q=%22used+tires%22" 
                tirestoresurl = "http://www.yellowpages.com/" + URI::encode(city.downcase) + "/used-tire-dealers?page=#{i}&q=#{URI::encode(self.YPKeywords())}" 
                @yp_url = tirestoresurl if @yp_url.blank?

                puts "#{tirestoresurl}"

                search_response = ReadData tirestoresurl

                if search_response.nil?
                    err_count += 1
                    if err_count > 25
                        result << "Too many errors, I false up.  Try again later."
                        @success = false
                        return result
                    else
                        result << "Error processing #{tirestoresurl} - I'll wait 15 seconds and try the next city."
                        sleep 15
                        next
                    end
                end    

                if search_response.to_s.include?("No results for")
                    break
                end

                html_tire_listings = Nokogiri::HTML(search_response.to_s)   

                html_tire_listings.xpath("//div[@class='info']").each do |tirestore|
                    store_name  = tirestore.xpath("div[@class='business-container-inner']/div/div[@class='business-name-wrapper']/h3/div/a").text().strip()
                    store_addr  = tirestore.xpath("div[@class='business-container-inner']/div[@class='info-business-wrapper']/div[@class='info-business']/span[@class='listing-address adr']/span[@class='street-address']").text().strip().chomp(',')
                    store_city  = tirestore.xpath("div[@class='business-container-inner']/div[@class='info-business-wrapper']/div[@class='info-business']/span[@class='listing-address adr']/span[@class='city-state']/span[@class='locality']").text().strip()
                    store_state = tirestore.xpath("div[@class='business-container-inner']/div[@class='info-business-wrapper']/div[@class='info-business']/span[@class='listing-address adr']/span[@class='city-state']/span[@class='region']").text().strip()
                    store_zip   = tirestore.xpath("div[@class='business-container-inner']/div[@class='info-business-wrapper']/div[@class='info-business']/span[@class='listing-address adr']/span[@class='city-state']/span[@class='postal-code']").text().strip()
                    store_phone = tirestore.xpath("div[@class='business-container-inner']/div[@class='info-business-wrapper']/div[@class='info-business']/span[@class='business-phone phone']").text().strip()

                    puts "name: #{store_name} addr: #{store_addr} city: #{store_city} state: #{store_state} zip: #{store_zip} phone: #{store_phone}"

                    if !store_name.blank? and !store_addr.blank? and !store_city.blank? and
                        !store_state.blank? and !store_zip.blank? and !store_phone.blank?

                        begin
                            @row_count += 1
                            rec_count += 1

                            @worksheet[@row_count, 1] = ""
                            @worksheet[@row_count, 2] = ""
                            @worksheet[@row_count, 3] = ""
                            @worksheet[@row_count, 4] = ""
                            @worksheet[@row_count, 5] = "YP #{c}"
                            @worksheet[@row_count, 6] = store_phone
                            @worksheet[@row_count, 7] = store_name
                            @worksheet[@row_count, 8] = store_addr
                            @worksheet[@row_count, 9] = ""
                            @worksheet[@row_count, 10] = store_city
                            @worksheet[@row_count, 11] = store_state
                            @worksheet[@row_count, 12] = store_zip
                            
                            @worksheet.save
                        rescue Exception => e 
                            result << e.backtrace
                            puts "We had an exception - skipping for now (" + e.message + ")."
                        end
                    end
                end                
            end

            begin
                @worksheet.save
            rescue Exception => e
                @success = false
            end

            result << "-----------------------------------------------"
            result << "YP - Scraped #{rec_count} records for #{city}"
            result << "-----------------------------------------------"
        end
        @status = true
        return result
    end

	def scrape_google
		result = []
        err_count = 0

		@city_array.each do |c|
			city = "#{c}, #{@state}"

            #row_count = @worksheet.num_rows

            query = "#{keywords} #{city}"
            startURL = "http://maps.google.com/maps?q=#{URI::encode(query)}"
            @google_url = startURL

            search_response = ReadData startURL

            if search_response.nil?
                err_count += 1
                if err_count > 25
                    result << "Too many errors, I give up.  Try again later."
                    @success = false
                    return result
                else
                    result << "Error processing #{startURL} - I'll wait 15 seconds and try the next city."
                    sleep 15
                    next
                end
            end            

            rec_count = 0

            while true do
                html_search = Nokogiri::HTML(search_response.to_s)
                
                nextURL = ""
                #html_search.xpath("//div[@class='text vcard indent block']").each do |used_tire_store|
                html_search.xpath("//div[@class='text vcard indent block']").each do |used_tire_store|
                    store_name = used_tire_store.xpath("div[@class='name lname']/span").text().strip()
                    store_addr_raw = used_tire_store.xpath("div/span[@class='pp-headline-item pp-headline-address']").text().strip()
                    store_phone_raw = used_tire_store.xpath("div/div/span[@class='pp-headline-item pp-headline-phone']/span/nobr").text().strip()
                    
                   	loc = nil
                   	(1..3).each do |i|
                   		loc = nil
                   		begin
                        geo = Geocoder.search(store_addr_raw)
                        loc = geo.first
                    	rescue Exception => e
                        result << e.message
                        loc = nil
                    	end

	                    if !loc.nil?
                          @row_count += 1
                          rec_count += 1
                          
                          a = store_addr_raw.split(",")
                          if a.size == 3
                            store_addr_parsed  = a.first.strip()
                            store_city_parsed  = a.second.strip()
                            store_state_parsed = a.third.strip()
                          else
                            store_addr_parsed = loc.address_data["addressLine"]
                            store_city_parsed = loc.city
                            store_state_parsed = loc.state
                          end                                      

                          @worksheet[@row_count, 1] = ""
                          @worksheet[@row_count, 2] = ""
                          @worksheet[@row_count, 3] = ""
                          @worksheet[@row_count, 4] = ""
                          @worksheet[@row_count, 5] = "Google #{c}"
                          @worksheet[@row_count, 6] = store_phone_raw
                          @worksheet[@row_count, 7] = store_name
                          #@worksheet[row_count, 2] = store_addr_raw
	                        ###s = loc.address_data["addressLine"]
	                        ###@worksheet[@row_count, 8] = s
                          @worksheet[@row_count, 8] = store_addr_parsed
                          @worksheet[@row_count, 9] = ""
	                        #@worksheet[@row_count, 10] = loc.city
                          @worksheet[@row_count, 10] = store_city_parsed
	                        #@worksheet[@row_count, 11] = loc.state
                          @worksheet[@row_count, 11] = store_state_parsed
	                        @worksheet[@row_count, 12] = loc.postal_code
	                        
                          (1..3).each do |j|
                            begin
                              @worksheet.save
                              break
                            rescue Exception => e
                              sleep 5
                            end
                          end

	                        break
	                    elsif store_addr_raw.strip().size > 0
                        result << "Attempt #{i}: Unable to geocode #{store_addr_raw} - store: #{store_name}"
	                    end
	                end
                end

                nextURL = html_search.xpath("//div[@id='nn']/../@href")
                if nextURL.length == 0
                    break
                end

                search_response = ReadData("http://maps.google.com#{nextURL}")
            end
            begin
                @worksheet.save
            rescue Exception => e
            	@success = false
            end

            result << "-----------------------------------------------"
            result << "Google - Scraped #{rec_count} records for #{city}"
            result << "-----------------------------------------------"
        end

        if !@spreadsheet.nil?
        	result.insert(0, "Document URL is https://docs.google.com/spreadsheet/ccc?key=#{@key}")
        end
        @status = true
        return result
    end

	def scrape(should_i_scrape_google, should_i_scrape_yp)
		@success = false
        @new_format = true

        begin
            @city_array = @cities.split("\r")

            log = []            

            @session = nil
            begin
                @session = GoogleDrive.login(@email, @password)

            rescue Exception => e
                log << "Unable to log in with the supplied credentials."
                @status = false
                raise "Could not log in"
            end


            @spreadsheet = nil
            begin
                @spreadsheet = @session.spreadsheet_by_key(@key)
                @spreadsheet.title = "Tire Store Scrape - #{@state}"
            rescue Exception => e
                log << "Unable to open spreadsheet with given key."
                @status = false
                raise "Could not open spreadsheet"
            end

            @worksheet = nil
            begin
                title = "#{state} - #{Time.now.to_s(:w3c)}"
                @worksheet = @spreadsheet.add_worksheet(title, 200, 7)
                @worksheet.title = title

                @worksheet[1, 1] = "Salutation (Optional)"
                @worksheet[1, 2] = "First name (Optional)"
                @worksheet[1, 3] = "Middle (Optional)"
                @worksheet[1, 4] = "Last Name (Required if company is not provided)"
                @worksheet[1, 5] = "Suffix (Optional)"
                @worksheet[1, 6] = "Title (Optional)" # phone
                @worksheet[1, 7] = "Company (Required if last name is not provided)"
                @worksheet[1, 8] = "Address Line 1 (Required)"
                @worksheet[1, 9] = "Address Line 2 (Optional)"
                @worksheet[1, 10] = "City (Required)"
                @worksheet[1, 11] = "State (Required)"
                @worksheet[1, 12] = "Zip+4 (At least 5-digit zip is required)"

                @row_count = 1

                @worksheet.save
            rescue Exception => e
                log << "Unable to create a new worksheet named #{title}."
                @status = false
                raise "Could not create worksheet"
            end

            if should_i_scrape_google
              log = scrape_google()
            end

            if should_i_scrape_yp
                log = log | scrape_yp()
            end
        rescue Exception => e 
            log = []
            log << "Exception processing data: #{e.message}"
            e.backtrace.each do |msg|
                log << msg
            end
        end

		if @status
			result_str = "success"
		else
			result_str = "failed"
		end

		TirestorescraperMailer.delay.scrape_done(@email, @key, @city_array, @state, log, result_str, @google_url, @yp_url)
	end
end