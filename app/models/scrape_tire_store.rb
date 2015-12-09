include ApplicationHelper

class ScrapeTireStore < ActiveRecord::Base
  serialize :google_properties, ActiveRecord::Coders::Hstore

  attr_accessible :name, :store_id, :additional_info, :address1, :address2, :city, :state, :zipcode, :phone
  attr_accessible :scraper_id, :latitude, :longitude, :account_id
  attr_accessible :google_properties
  
  attr_accessible :th_customer_sql
  
  composed_of :address, :class_name => "Address"
  after_validation :geocode
  before_validation :validate_phone
  geocoded_by :real_address
  reverse_geocoded_by :latitude, :longitude
  
  def th_customer
    if @th_customer_sql.nil? || @account_id.nil?
      false
    else
      @th_customer_sql.to_bool
    end
  end
  
  def self.full_distance_query(latitude, longitude, lat_attr, lon_attr)
    earth = Geocoder::Calculations.earth_radius(:mi)

    "#{earth} * 2 * ASIN(SQRT(" +
      "POWER(SIN((#{latitude.to_f} - #{lat_attr}) * PI() / 180 / 2), 2) + " +
      "COS(#{latitude.to_f} * PI() / 180) * COS(#{lat_attr} * PI() / 180) * " +
      "POWER(SIN((#{longitude.to_f} - #{lon_attr}) * PI() / 180 / 2), 2)" +
    "))"
  end
  
  def real_address
    "#{self.address1} #{self.address2}, #{self.city}, #{self.state} #{self.zipcode}"
  end
  
  def validate_phone
    if self.phone
      self.phone = self.phone.gsub(/\D/, '') # remove non-numeric chars
    end
  end
  
  def visible_phone
    number_to_phone(self.phone, :area_code => true)
  end
  
  def self.offset_query(page_no, recs_per_page)
    page_no = page_no.to_i
    if recs_per_page <= 0
      recs_per_page = 50
    end
    if page_no <= 1
      page_no = 1
    end
    "LIMIT #{recs_per_page} OFFSET #{50 * (page_no - 1)}"
  end
  
  def self.search_all_stores_by_location(location, distance, keywords, page_no, recs_per_page)
    latitude, longitude = Geocoder::Calculations.extract_coordinates(location)
    if Geocoder::Calculations.coordinates_present?(latitude, longitude)
      ScrapeTireStore.search_all_stores(latitude, longitude, distance, keywords, page_no, recs_per_page)
    else
      ScrapeTireStore.all_stores(keywords, page_no, recs_per_page)
    end
  end
  
  def self.all_stores(keywords, page_no, recs_per_page)
    sSQL = "SELECT tire_stores.id, tire_stores.account_id, tire_stores.name, tire_stores.address1, tire_stores.address2, tire_stores.city, tire_stores.state, tire_stores.zipcode, tire_stores.phone, true AS th_customer_sql, tire_stores.google_properties, tire_stores.other_properties " +
      " FROM tire_stores " +
      " WHERE private_seller = false " +
      (keywords.blank? ? "" : " AND name ~* #{TireStore.sanitize(keywords)}") +
      " UNION " +
      " SELECT id, null as account_id, scrape_tire_stores.name, scrape_tire_stores.address1, scrape_tire_stores.address2, scrape_tire_stores.city, scrape_tire_stores.state, scrape_tire_stores.zipcode, scrape_tire_stores.phone, false AS th_customer_sql, scrape_tire_stores.google_properties, null as other_properties " +
      " FROM scrape_tire_stores " +
      (keywords.blank? ? "" : " WHERE name ~* #{ScrapeTireStore.sanitize(keywords)}") +
      " ORDER BY th_customer_sql DESC, name ASC " +
      " LIMIT 1000" #ScrapeTireStore.offset_query(page_no, recs_per_page)
      
      TireStore.find_by_sql(sSQL)    
  end
  
  def self.search_all_stores(latitude, longitude, distance, keywords, page_no, recs_per_page)
    sSQL = "SELECT tire_stores.id, tire_stores.account_id, tire_stores.name, tire_stores.address1, tire_stores.address2, tire_stores.city, tire_stores.state, tire_stores.zipcode, tire_stores.phone, tire_stores.latitude, tire_stores.longitude, " +
      full_distance_query(latitude, longitude, "tire_stores.latitude", "tire_stores.longitude") + " AS distance, true AS th_customer_sql, tire_stores.google_properties, tire_stores.other_properties " +
      " FROM tire_stores WHERE " +
      full_distance_query(latitude, longitude, "tire_stores.latitude", "tire_stores.longitude") + " < #{distance} " +
      " AND private_seller = false " + 
      (keywords.blank? ? "" : " AND name ~* '#{keywords}'") + 
      " UNION " +
      " SELECT id, null as account_id, scrape_tire_stores.name, scrape_tire_stores.address1, scrape_tire_stores.address2, scrape_tire_stores.city, scrape_tire_stores.state, scrape_tire_stores.zipcode, scrape_tire_stores.phone, scrape_tire_stores.latitude, scrape_tire_stores.longitude, " +
      full_distance_query(latitude, longitude, "scrape_tire_stores.latitude", "scrape_tire_stores.longitude") + " AS distance, false AS th_customer_sql, scrape_tire_stores.google_properties, null as other_properties " +
      " FROM scrape_tire_stores WHERE " +
      full_distance_query(latitude, longitude, "scrape_tire_stores.latitude", "scrape_tire_stores.longitude") + " < #{distance} " +
      (keywords.blank? ? "" : " AND name ~* '#{keywords}'") +
      " ORDER BY th_customer_sql DESC, distance ASC " +
      (page_no == 0 ? "LIMIT #{recs_per_page}" : "LIMIT 1000")
      
      TireStore.find_by_sql(sSQL)
  end

  def hours_not_available?
    if sunday_open.blank? && monday_open.blank? && tuesday_open.blank? && wednesday_open.blank? &&
      thursday_open.blank? && friday_open.blank? && saturday_open.blank?
      return true
    else
      return false
    end
  end  

  ################################################################
  def set_fields_from_google_place(google_place)
    self.name = google_place.name
    self.address1 = "#{google_place.street_number} #{google_place.street}"
    self.address2 = ""
    self.city = google_place.city
    self.state = google_place.region
    self.zipcode = google_place.postal_code
    self.phone = google_place.formatted_phone_number
    self.latitude = google_place.lat
    self.longitude = google_place.lng 
    ###self.website = google_place.website

    #################################################
    #if !google_place.photos.nil? && google_place.photos.size > 0
    #  begin
    #      self.logo = google_place.photos[0].fetch_url(800)
    #    rescue
    #    end
    #end
    #################################################

    self.google_place_id = google_place.id
    self.google_reference = google_place.reference
    self.google_website = google_place.website
    self.google_plus_url = google_place.url

    if !google_place.opening_hours.blank?
      begin
        google_place.opening_hours["periods"].each do |day|
          open_time = day["open"]["time"]
          close_time = day["close"]["time"]

          open_time = "#{open_time[0..1]}:#{open_time[2..3]}"
          close_time = "#{close_time[0..1]}:#{close_time[2..3]}"

          if !(day["open"].nil?)
            case day["open"]["day"]
              when 0
                self.sunday_open = open_time
              when 1
                self.monday_open = open_time
              when 2
                self.tuesday_open = open_time
              when 3
                self.wednesday_open = open_time
              when 4
                self.thursday_open = open_time
              when 5
                self.friday_open = open_time
              when 6
                self.saturday_open = open_time
            end
          end

          if !(day["close"].nil?)
            case day["close"]["day"]
              when 0
                self.sunday_close = close_time
              when 1
                self.monday_close = close_time
              when 2
                self.tuesday_close = close_time
              when 3
                self.wednesday_close = close_time
              when 4
                self.thursday_close = close_time
              when 5
                self.friday_close = close_time
              when 6
                self.saturday_close = close_time
            end
          end
        end
      rescue
      end
    end
  end

  def get_google_place_record
    if self.google_place_id.blank?
      return nil 
    else
      begin
        return GooglePlaces::Spot.find(self.google_place_id, google_places_api_key())
      rescue
        return nil 
      end
    end
  end

  def self.fix_google_place_id
    all_stores = ScrapeTireStore.find_all_with_google_reference

    all_stores.each do |ts|
      if !ts.get_google_place_record.nil?
        puts "Skipping because already fixed."
      else
        begin
          spot = GooglePlaces::Request.spot({:reference => ts.google_reference, :key => google_places_api_key()})
          place_id = spot["result"]["place_id"]
          ts.google_place_id = place_id
        rescue
          ts.google_place_id = ""
        end
        ts.save
      end
    end
  end

  def self.find_by_google_place_id(place_id)
    result = ScrapeTireStore.where("google_properties -> 'google_place_id' = '#{place_id}'")
    if result.size == 0
      result = nil
    end

    return result
  end

  def self.find_all_with_google_reference
    result = ScrapeTireStore.where("google_properties ? 'reference'")
    if result.size == 0
      result = nil
    end

    return result
  end

  def google_plus_url
    self.google_properties['google_plus_url']
  end

  def google_plus_url=(plus_url)
    if plus_url.blank?
      self.destroy_key(:google_properties, :google_plus_url)
    else
      self.google_properties['google_plus_url'] = plus_url
    end
  end

  def google_website
    self.google_properties['google_website']
  end

  def google_website=(website)
    if website.blank?
      self.destroy_key(:google_properties, :google_website)
    else
      self.google_properties['google_website'] = website
    end
  end

  def google_place_id
    self.google_properties['google_place_id']
  end

  def google_place_id=(place_id)
    if place_id.blank?
      self.destroy_key(:google_properties, :google_place_id)
    else
      self.google_properties['google_place_id'] = place_id
    end
  end

  def google_reference
    self.google_properties['reference']
  end

  def google_reference=(reference)
    if reference.blank?
      self.destroy_key(:google_properties, :reference)
    else
      self.google_properties['reference'] = reference
    end
  end

  def get_weekday_open(dow)
    return self.google_properties["#{dow}_open"]
  end

  def set_weekday_open(dow, time)
    if time.blank?
      self.destroy_key(:google_properties, "#{dow}_open")
    else
      self.google_properties["#{dow}_open"] = time
    end
  end

  def get_weekday_close(dow)
    return self.google_properties["#{dow}_close"]
  end

  def set_weekday_close(dow, time)
    if time.blank?
      self.destroy_key(:google_properties, "#{dow}_close")
    else
      self.google_properties["#{dow}_close"] = time
    end
  end

  def monday_open
    get_weekday_open("monday")
  end

  def monday_open=(time)
    set_weekday_open("monday", time)
  end

  def monday_close
    get_weekday_close("monday")
  end

  def monday_close=(time)
    set_weekday_close("monday", time)
  end

  def tuesday_open
    get_weekday_open("tuesday")
  end

  def tuesday_open=(time)
    set_weekday_open("tuesday", time)
  end

  def tuesday_close
    get_weekday_close("tuesday")
  end

  def tuesday_close=(time)
    set_weekday_close("tuesday", time)
  end

  def wednesday_open
    get_weekday_open("wednesday")
  end

  def wednesday_open=(time)
    set_weekday_open("wednesday", time)
  end

  def wednesday_close
    get_weekday_close("wednesday")
  end

  def wednesday_close=(time)
    set_weekday_close("wednesday", time)
  end

  def thursday_open
    get_weekday_open("thursday")
  end

  def thursday_open=(time)
    set_weekday_open("thursday", time)
  end

  def thursday_close
    get_weekday_close("thursday")
  end

  def thursday_close=(time)
    set_weekday_close("thursday", time)
  end

  def friday_open
    get_weekday_open("friday")
  end

  def friday_open=(time)
    set_weekday_open("friday", time)
  end

  def friday_close
    get_weekday_close("friday")
  end

  def friday_close=(time)
    set_weekday_close("friday", time)
  end

  def saturday_open
    get_weekday_open("saturday")
  end

  def saturday_open=(time)
    set_weekday_open("saturday", time)
  end

  def saturday_close
    get_weekday_close("saturday")
  end

  def saturday_close=(time)
    set_weekday_close("saturday", time)
  end

  def sunday_open
    get_weekday_open("sunday")
  end

  def sunday_open=(time)
    set_weekday_open("sunday", time)
  end

  def sunday_close
    get_weekday_close("sunday")
  end

  def sunday_close=(time)
    set_weekday_close("sunday", time)
  end

  def external_url
    if !self.google_website.blank?
      return self.google_website
    elsif !self.google_plus_url.blank?
      return self.google_plus_url
    else
      return ""
    end
  end

  def hours_as_string(day_int, format_as_today)
    if format_as_today
        sResult = "" # "Hours: Not specified"
    else
      sResult = "" # "#{Date::DAYNAMES[day_int]}: Not specified"
    end     
      begin
        if !self.google_properties.blank?
          if self.google_properties.to_s == '{"sunday_open"=>"00:00"}'
            if format_as_today
              sResult = "Open 24 Hours"
            else
              sResult = "#{Date::DAYNAMES[day_int]}: Open 24 Hours"
            end
          else
            start_time = ""
            end_time = ""

            case day_int
              when 0
                start_time = sunday_open
                end_time = sunday_close
              when 1
                start_time = monday_open
                end_time = monday_close
              when 2
                start_time = tuesday_open
                end_time = tuesday_close
              when 3
                start_time = wednesday_open
                end_time = wednesday_close
              when 4
                start_time = thursday_open
                end_time = thursday_close
              when 5
                start_time = friday_open
                end_time = friday_close
              when 6
                start_time = saturday_open
                end_time = saturday_close
            end

            if !start_time.blank? && end_time.blank?
              if format_as_today
                sResult = "Open today " + Time.parse(start_time).strftime("%l:%M %P").strip()
              else
                sResult = "#{Date::DAYNAMES[day_int]}: Open " + Time.parse(start_time).strftime("%l:%M %P").strip()
              end
            elsif start_time.blank? || end_time.blank?
              if format_as_today
                sResult = "Closed today"
              else
                sResult = "#{Date::DAYNAMES[day_int]}: Closed"
              end
            elsif start_time == "00:00" && end_time == "24:00"
              if format_as_today
                sResult = "Open 24 Hours"
              else
                sResult = "#{Date::DAYNAMES[day_int]}: Open 24 Hours"
              end
            else
              if format_as_today
                sResult = "Open today " + Time.parse(start_time).strftime("%l:%M %P").strip() + " - " + Time.parse(end_time).strftime("%l:%M %P").strip()
              else
                sResult = "#{Date::DAYNAMES[day_int]}: Open " + Time.parse(start_time).strftime("%l:%M %P").strip() + " - " + Time.parse(end_time).strftime("%l:%M %P").strip()
              end
            end
          end
        end
      rescue Exception => e
        puts "******"
        puts "#{day_int} #{google_properties} #{e.to_s}"
        puts "******"
        if format_as_today
          sResult = "Hours: Not specified"
        else
          sResult = "#{Date::DAYNAMES[day_int]}: Hours not specified"
        end
      end

      return sResult
    end

    def today_hours
      hours_as_string(Date.today.wday, true)
    end

    def consumer_rating
      nil
    end

    def hours_open_as_string_array
      result = []

      (0..6).each do |wday|
        result << hours_as_string(wday, false)
      end

      return result
    end
  ################################################################

end
