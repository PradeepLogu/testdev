class TireSearch < ActiveRecord::Base
  include ApplicationHelper
  include TireStoresHelper
  attr_accessible :auto_manufacturer_id, :auto_model_id, :auto_year_id, 
                  :auto_options_id, :locationstr, :radius, :user_id, :latitude, 
                  :longitude, :quantity, :saved_search_frequency, :saved_search_dow,
                  :send_text, :text_phone, :new_or_used,
                  :tire_manufacturer_id, :tire_model_id   # DG - these two added for the new ways to search tires
  attr_accessor :low_price, :high_price, :only_fresh, :max_recs, :sort_order
  attr_accessor :is_new_filter, :quantity_filter, :wheeldiameter_filter, :tire_type_filter
  attr_accessor :cost_per_tire_min_filter, :cost_per_tire_max_filter
  attr_accessor :treadlife_min_filter, :treadlife_max_filter, :seller_filter
  attr_accessor :tire_manufacturer_id_filter, :tire_category_id_filter
  attr_accessor :exclude_generic_filter
  attr_accessor :width_filter, :ratio_filter
  belongs_to :tire_size
  accepts_nested_attributes_for :tire_size
  belongs_to :auto_option
  belongs_to :auto_year
  belongs_to :auto_model
  belongs_to :auto_manufacturer
  belongs_to :tire_model
  belongs_to :tire_manufacturer
  belongs_to :user
  geocoded_by :locationstr
  after_initialize :afterinitialize
  before_save :set_coordinates
  before_validation :validate_phone
  validates_presence_of :locationstr, :message => "Enter a search location - street address, city/state, or zip."
  validates_length_of :text_phone, :presence => true, :maximum => 10, :minimum => 10, :if => :send_text
  
  def validate_phone
    self.text_phone = self.text_phone.gsub(/\D/, '') if self.text_phone # remove non-numeric chars
  end


  #RADIUS_CHOICES = ["5", "10", "20", "30", "50", "100", "500", ["Any", "99999"]]
  RADIUS_CHOICES = ["10", "20", "50"]
  QUANTITY_CHOICES = [["Any", ""], "1", "2", "3", "4"]
  NEW_OR_USED_CHOICES = [["All", "b"], ["New", "n"], ["Used", "u"]]
  ALT_NEW_OR_USED_CHOICES = [["New And Used", "b"], ["New", "n"], ["Used", "u"]]
  DEFAULT_MAX = 500 #100

    def set_coordinates
      if valid_geography?
        self.latitude = @search_result[0].latitude
        self.longitude = @search_result[0].longitude
      end
    end

    def new_or_used_desc(srchStr)
      returnStr = "All"
      NEW_OR_USED_CHOICES.each do |ar|
        if ar.size > 0 && ar[1].downcase == srchStr.downcase
          returnStr = ar[0]
        end
      end
      returnStr + " tires"
    end

    def search_link
      url = '/tire_searches/tireresults' + url_params('')
      puts "URL is #{url}"
      url
    end

    #Use "simplify" to leave out params not needed for searching listings on a tire store.
    def url_params(suffix, simplify = false)
      temp = []
      temp << "tire_model_id#{suffix}=#{self.tire_model_id}" if !self.tire_model_id.to_s.empty?
      temp << "tire_manufacturer_id#{suffix}=#{self.tire_manufacturer_id}" if !self.tire_manufacturer_id.to_s.empty?
      temp << "auto_manufacturer_id#{suffix}=#{self.auto_manufacturer_id}" if !self.auto_manufacturer_id.to_s.empty?
      temp << "auto_model_id#{suffix}=#{self.auto_model_id}" if !self.auto_model_id.to_s.empty?
      temp << "auto_year_id#{suffix}=#{self.auto_year_id}" if !self.auto_year_id.to_s.empty?
      temp << "auto_options_id#{suffix}=#{self.auto_options_id}" if !self.auto_options_id.to_s.empty?
      temp << "width#{suffix}=#{self.tire_size.diameter}" if self.tire_size && !self.tire_size.diameter.to_s.empty?
      temp << "ratio#{suffix}=#{self.tire_size.ratio}" if self.tire_size && !self.tire_size.ratio.to_s.empty?
      temp << "wheeldiameter#{suffix}=#{self.tire_size.wheeldiameter}" if self.tire_size && !self.tire_size.wheeldiameter.to_s.empty?
      if !simplify
        temp << "tire_search[locationstr]#{suffix}=#{self.locationstr}" if !self.locationstr.to_s.empty?
        temp << "tire_search[radius]#{suffix}=#{self.radius}" if !self.radius.to_s.empty?
        temp << "tire_search[quantity]#{suffix}=#{self.quantity}" if !self.quantity.to_s.empty?
        temp << "o=1"
      end
      
      return "?" + temp.join('&')
    end

    def search_description
      begin
        (self.tire_manufacturer.nil? ? '' : self.tire_manufacturer.name + ' ') +
        (self.tire_model.nil? ? '' : self.tire_model.name + ' ') +
        (self.auto_year.nil? ? '' : self.auto_year.modelyear + ' ') +
        (self.auto_manufacturer.nil? ? '' : self.auto_manufacturer.name + ' ') +
        (self.auto_model.nil? ? '' : self.auto_model.name + ' ') +
        (self.auto_option.nil? ? '' : self.auto_option.name + ' ') +
        (self.auto_year.nil? ? '' : '(') + 
        (self.tire_size.nil? ? '' : self.tire_size.sizestr) +
        (self.auto_year.nil? ? '' : ')')
        #(self.geo_level.nil? ? '' : ' for ' + self.geo_level)
        #(self.new_or_used.nil? ? "" : " (#{new_or_used_desc(new_or_used)})")
      rescue
      end
    end

    def afterinitialize
      auto_manufacturer_id = auto_model_id = auto_year_id = auto_options_id = 0
      tire_model_id = tire_manufacturer_id = 0
      locationstr = ''
      quantity = radius = user_id = 0
      @tire_size = TireSize.first
    end

    def paginated_tirelistings_page(page_no)
      find_tirelistings.paginate(page: page_no, :per_page => 100)
    end

    def paginated_tirelistings(params)
      find_tirelistings.paginate(page: params[:page], :per_page => 100)
    end
    
    def consolidated_tirelistings_page(page_no)
      ConsolidatedTireListing.insert_consolidated_listings(self.paginated_tirelistings_page(page_no)) #(self.tirelistings)
    end
    
    def consolidated_tirelistings(params)
      ConsolidatedTireListing.insert_consolidated_listings(self.paginated_tirelistings(params)) #(self.tirelistings)     
    end
    
    def paginated_tirestores_page(page_no)
      tirestores.paginate(page: page_no, :per_page => 50)
    end

    def paginated_tirestores(params)
      tirestores.paginate(page: params[:page], :per_page => 50)
    end

    def tirelistings 
    	@tirelistings ||= find_tirelistings.first(max_recs.to_i <= 0 ? DEFAULT_MAX : max_recs)
    end
    
    # DG - New search method to only find store info for stores with matches
    def tirestores
      @tirestores ||= find_tirestores
    end

    def used_tirelistings
      tirelistings.select {|i| i.is_new == false}
    end

    def new_tirelistings
      tirelistings.select {|i| i.is_new == true}
    end

    def listings_sortorder
      self.sort_order = SortOrder::SORT_BY_DISTANCE_ASC if self.sort_order.nil?
      
      puts "*** SORT ORDER IS *** #{self.sort_order}"

      case self.sort_order
      when SortOrder::SORT_BY_MANU_ASC
        "tire_manufacturers.name ASC"
      when SortOrder::SORT_BY_MANU_DESC
        "tire_manufacturers.name DESC"
      when SortOrder::SORT_BY_SIZE_ASC
        "tire_sizes.sizestr ASC"
      when SortOrder::SORT_BY_SIZE_DESC
        "tire_sizes.sizestr DESC"
      when SortOrder::SORT_BY_UPDATED_ASC
        "tire_listings.updated_at ASC"
      when SortOrder::SORT_BY_UPDATED_DESC
        "tire_listings.updated_at DESC"
      when SortOrder::SORT_BY_QTY_ASC
        "tire_listings.quantity ASC"
      when SortOrder::SORT_BY_QTY_DESC
        "tire_listings.quantity DESC"
      when SortOrder::SORT_BY_TYPE_ASC
        "tire_categories.category_name ASC"
      when SortOrder::SORT_BY_TYPE_DESC
        "tire_categories.category_name DESC"
      when SortOrder::SORT_BY_TREADLIFE_ASC
        "tire_listings.treadlife ASC"
      when SortOrder::SORT_BY_TREADLIFE_DESC
        "tire_listings.treadlife DESC"
      when SortOrder::SORT_BY_DISTANCE_ASC
        "distance ASC"
      when SortOrder::SORT_BY_DISTANCE_DESC
        "distance DESC"
      when SortOrder::SORT_BY_COST_PER_TIRE_ASC
        "CASE WHEN tire_listings.is_new = true THEN (tire_listings.price::float / 100) ELSE (tire_listings.price::float / (100 * tire_listings.quantity)) END ASC"
      when SortOrder::SORT_BY_COST_PER_TIRE_DESC
        "CASE WHEN tire_listings.is_new = true THEN (tire_listings.price::float / 100) ELSE (tire_listings.price::float / (100 * tire_listings.quantity)) END DESC"
      else
        "tire_listings.updated_at DESC"
      end
    end
    
    def stores_sortorder
      self.sort_order = SortOrder::SORT_BY_DISTANCE_ASC if self.sort_order.nil?
      
      puts "*** SORT ORDER IS *** #{self.sort_order}"

      case self.sort_order
      when SortOrder::SORT_BY_STORE_NAME_ASC
        "tire_stores.name ASC"
      when SortOrder::SORT_BY_STORE_NAME_DESC
        "tire_stores.name DESC"
      when SortOrder::SORT_BY_DISTANCE_ASC
        "distance ASC"
      when SortOrder::SORT_BY_DISTANCE_DESC
        "distance DESC"
      else
        "distance ASC"
      end
    end

    def find_tirelistings
      if locationstr.blank? || radius.nil? || (radius.is_a?(Fixnum) && radius <= 0)
        puts "*** CONDITIONS: #{conditions} ORDER #{listings_sortorder}"
        TireListing.includes(:tire_size, :tire_manufacturer, :tire_model, :tire_category, :tire_store).limit(max_recs.to_i <= 0 ? DEFAULT_MAX * 2 : max_recs * 2).where(conditions).order(listings_sortorder)
      else
        puts "*** CONDITIONS: #{conditions} ORDER #{listings_sortorder}"
        #TireListing.includes(:tire_size, :tire_manufacturer, :tire_model, :tire_category).near(locationstr, radius).limit(max_recs.to_i <= 0 ? DEFAULT_MAX * 2 : max_recs * 2).where(conditions).reorder(listings_sortorder)
        ar = []
        i = 0
        while ar.empty? && i <= 5
          puts "Searching: i = #{i}"
          i += 1
          ar = TireListing.near(locationstr, radius).limit(max_recs.to_i <= 0 ? DEFAULT_MAX * 2 : max_recs * 2).joins("left outer join tire_sizes on tire_sizes.id = tire_size_id left outer join tire_manufacturers on tire_manufacturers.id = tire_manufacturer_id left outer join tire_models on tire_models.id = tire_model_id left outer join tire_categories on tire_categories.id = tire_models.tire_category_id left outer join tire_stores on tire_stores.id = tire_store_id").where(conditions).reorder(listings_sortorder)
          if ar.empty? && !ar.to_sql.include?("NULL AS distance")
            # we are only going to re-run if we got NULL AS distance in the query, meaning the
            # geocoding failed...
            i = 6
          end
        end
        ar
      end
    end
    
    # DG - New search method to only find store info for stores with matches
    def find_tirestores
      if !locationstr.blank? && !radius.nil?
        puts "*** CONDITIONS: #{conditions}  (Store Search)"
        stores = TireStore.near(locationstr, radius).reorder(stores_sortorder)
        
        if stores.length > 0
          store_ids = stores.collect{ |s| s.id }
          listings = TireListing.includes(:tire_size, :tire_manufacturer, :tire_model, :tire_category)
                                .where(tire_store_id: store_ids).where(conditions)
                                .select('tire_listings.tire_store_id, COUNT(*) AS "listings_count", MAX(tire_listings.price) AS "max_price", MIN(tire_listings.price) AS "min_price"')
                                .group(:tire_store_id)
          if listings.length > 0
            stores.each do |s|
              i = listings.index{|x| x[:tire_store_id] == s.id}
              if i
                s[:listings_count] = listings[i].listings_count
                s[:max_price] = listings[i].max_price
                s[:min_price] = listings[i].min_price
              else
                s = nil
              end
            end
            stores.compact!
          else
            stores = []
          end
        end
        stores
      else
        raise "Tire Store Search: Missing locationstr or radius!" 
      end
    end

    def price_conditions
      return ["price >= ? * 100 and price <= ? * 100", @low_price, @high_price] unless @low_price.blank? || @high_price.blank?
      return ["price >= ? * 100", @low_price] unless @low_price.blank? 
      return ["price <= ? * 100", @high_price] unless @high_price.blank? 
    end

    def tiresize_conditions
    	["tire_listings.tire_size_id = ?", tire_size_id] unless tire_size_id.blank?
    end

    def tiremodel_conditions
      ["tire_listings.tire_model_id = ?", tire_model_id] unless tire_model_id.blank?
    end
    
    def tiremanufacturer_conditions
      ["tire_listings.tire_manufacturer_id = ?", tire_manufacturer_id] unless tire_manufacturer_id.blank?
    end

    def quantity_conditions
      ["(quantity = ? or is_new = true or (sell_as_set_only = false and quantity >= ?))", quantity, quantity] unless quantity.blank? or quantity < 1 or quantity > 4
    end

    def status_conditions
      ["tire_listings.status = ?", status_array[:active]]
    end

    def is_new_conditions
      if new_or_used.downcase == 'n'
        ["is_new = ?", true]
      elsif new_or_used.downcase == 'u'
        ["is_new = ?", false]
      end
    end

    def freshness_conditions
      ["created_at >= ?", updated_at] if only_fresh
    end

    def conditions
    	#[conditions_clauses.join(' AND '), *conditions_options]
      c = [(conditions_clauses.concat(filters_clauses)).join(' AND '), *(conditions_options.concat(filters_options))]      
    end

    def conditions_clauses
    	conditions_parts.map { |condition| condition.first }
    end

    def conditions_options
    	conditions_parts.map { |condition| condition[1..-1] }.flatten
    end

    def conditions_parts
    	methods.grep(/_conditions$/).map { |m| send(m) }.compact
    end

    def valid_geography?
      puts "Checking geography..."
      backtrace_log if backtrace_logging_enabled
      @search_result ||= geocode_search
      !@search_result[0].nil?
    end

    def geocode_search
      geo = []
      i = 0
      while geo.empty? && i <= 2
        geo = Geocoder.search(locationstr)
        i = i + 1
      end
      backtrace_log if backtrace_logging_enabled
      geo
    end

    def geo_level
      if valid_geography?
        if @search_result.respond_to?(:address_components)
          # Google search gives us more details...
          case @geolocation[0].address_components[0]["types"][0]
          when "postal_code"
            "a " + radius.to_s + " mile radius of zipcode=" + @geolocation[0].address_components[0]["long_name"].to_s + 
              " (" + @geolocation[0].address_components[1]["long_name"].to_s + ", " + 
              @geolocation[0].address_components[2]["short_name"].to_s + ")"
          when "locality"
            "a " + radius.to_s + " mile radius of " + @geolocation[0].address_components[0]["long_name"].to_s + "," + 
              @geolocation[0].address_components[2]["short_name"].to_s 
          when "street_number"
            "a " + radius.to_s + " mile radius of " + @geolocation[0].address_components[0]["long_name"].to_s +
              " " + @geolocation[0].address_components[1]["short_name"].to_s + ", " +
              @geolocation[0].address_components[2]["long_name"].to_s + " " + @geolocation[0].address_components[4]["short_name"].to_s 
          when "sublocality"
            "a " + radius.to_s + " mile radius of " + @geolocation[0].address_components[0]["long_name"].to_s +
              ", " + @geolocation[0].address_components[2]["short_name"].to_s
          else
            @geolocation[0].address_components[0]["types"][0] 
          end
        else
          @search_result[0].address
        end
      end
    end

    def valid_geography_old?
      begin
        @geolocation ||= geocode_location
        self.latitude = @geolocation[0].geometry["location"]["lat"]
        self.longitude = @geolocation[0].geometry["location"]["lng"]
        @geolocation.count == 1
      rescue Exception => e 
        puts "*** Geocoding error - " + e.message 
        false
      end
    end

    #private
      def geo_level_old
        if valid_geography?
          begin
            case @geolocation[0].address_components[0]["types"][0]
            when "postal_code"
              "a " + radius.to_s + " mile radius of zipcode=" + @geolocation[0].address_components[0]["long_name"].to_s + 
                " (" + @geolocation[0].address_components[1]["long_name"].to_s + ", " + 
                @geolocation[0].address_components[2]["short_name"].to_s + ")"
            when "locality"
              "a " + radius.to_s + " mile radius of " + @geolocation[0].address_components[0]["long_name"].to_s + "," + 
                @geolocation[0].address_components[2]["short_name"].to_s 
            when "street_number"
              "a " + radius.to_s + " mile radius of " + @geolocation[0].address_components[0]["long_name"].to_s +
                " " + @geolocation[0].address_components[1]["short_name"].to_s + ", " +
                @geolocation[0].address_components[2]["long_name"].to_s + " " + @geolocation[0].address_components[4]["short_name"].to_s 
            when "sublocality"
              "a " + radius.to_s + " mile radius of " + @geolocation[0].address_components[0]["long_name"].to_s +
                ", " + @geolocation[0].address_components[2]["short_name"].to_s
            else
              @geolocation[0].address_components[0]["types"][0] 
            end
            #@geolocation[0].address_components[0]["types"].to_s + '=' + @geolocation[0].address_components[0]["long_name"].to_s
          rescue
            locationstr
          end
        end
      end

      def geocode_location_old
        Geocoder.search(locationstr)
      end

      # filters
      def seller_filters
        ["tire_stores.private_seller = ?", seller_filter] unless seller_filter.blank?
      end

      def is_new_filters
        ["tire_listings.is_new = ?", is_new_filter] unless is_new_filter.blank?
      end

      def quantity_filters
        ["tire_listings.quantity = ?", quantity_filter] unless quantity_filter.blank?
      end

      def wheeldiameter_filters
        ["tire_sizes.wheeldiameter = ?", wheeldiameter_filter] unless wheeldiameter_filter.blank?
      end

      def width_filters
        ["tire_sizes.diameter = ?", width_filter] unless width_filter.blank?
      end

      def ratio_filters
        ["tire_sizes.ratio = ?", ratio_filter] unless ratio_filter.blank?
      end

      def tire_manufacturer_id_filters
        ["tire_manufacturers.id = ?", tire_manufacturer_id_filter] unless tire_manufacturer_id_filter.blank?
      end

      def tire_category_id_filters
        ["tire_categories.id = ?", tire_category_id_filter] unless tire_category_id_filter.blank?      
      end

      def tire_type_filters
        ["tire_models.tire_category_id = ?", tire_type_filter] unless tire_type_filter.blank?
      end

      def cost_per_tire_min_filters
        ["((tire_listings.is_new = true AND (tire_listings.price::float / 100) >= ?) OR (tire_listings.is_new = false AND tire_listings.quantity > 0 AND (tire_listings.price::float / (100 * tire_listings.quantity)) >= ?))", cost_per_tire_min_filter, cost_per_tire_min_filter] unless cost_per_tire_min_filter.blank?
      end

      def cost_per_tire_max_filters
        ["((tire_listings.is_new = true AND (tire_listings.price::float / 100) <= ?) OR (tire_listings.is_new = false AND tire_listings.quantity > 0 AND (tire_listings.price::float / (100 * tire_listings.quantity)) <= ?))", cost_per_tire_max_filter, cost_per_tire_max_filter] unless cost_per_tire_max_filter.blank?
      end

      def treadlife_min_filters
        ["treadlife >= ?", treadlife_min_filter] unless treadlife_min_filter.blank?
      end

      def treadlife_max_filters
        ["treadlife <= ?", treadlife_max_filter] unless treadlife_max_filter.blank?
      end

      def exclude_generic_filters
        if self.exclude_generic_filter.to_s.to_bool == true
          ["(tire_listings.is_generic = false)"]
        end
      end

      def filters
        [filters_clauses.join(' AND '), *filters_options]
      end

      def filters_clauses
        filters_parts.map { |filter| filter.first }
      end

      def filters_options
        filters_parts.map { |filter| filter[1..-1] }.flatten
      end

      def filters_parts
        methods.grep(/_filters$/).map { |m| send(m) }.compact
      end      
end
