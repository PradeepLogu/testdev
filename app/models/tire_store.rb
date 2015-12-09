include ActionView::Helpers::NumberHelper
include ApplicationHelper
include TireStoresHelper

class TireStore < ActiveRecord::Base
    require 'fuzzystringmatch'

    is_impressionable
  #serialize :colors, ActiveRecord::Coders::Hstore

  DEFAULT_APPT_LEAD_TIME_HRS = 4

  validates :contact_email, :presence => true
  attr_accessible :name, :phone, :address1, :address2, :city, :state, :zipcode
  attr_accessible :contact_email, :affiliate_id, :private_seller, :hide_phone
  attr_accessible :send_text, :text_phone, :domain, :authorized_promotion_tire_manufacturer_ids
  attr_accessible :affiliate_id, :affiliate_time, :affiliate_referrer
  attr_accessible :willing_to_ship, :brands_carried, :google_properties
  attr_accessible :other_properties

  attr_accessible :sunday_open, :sunday_close, :monday_open, :monday_close
  attr_accessible :tuesday_open, :tuesday_close, :wednesday_open, :wednesday_close
  attr_accessible :thursday_open, :thursday_close, :friday_open, :friday_close
  attr_accessible :saturday_open, :saturday_close

  serialize :google_properties, ActiveRecord::Coders::Hstore

  serialize :other_properties, ActiveRecord::Coders::Hstore

  serialize :financial_info, ActiveRecord::Coders::Hstore
  
  attr_accessor :tire_size_id, :tire_model_id, :tire_model_name, :sort_order
  attr_accessor :is_new_filter, :quantity_filter, :wheeldiameter_filter, :tire_type_filter
  attr_accessor :cost_per_tire_min_filter, :cost_per_tire_max_filter
  attr_accessor :treadlife_min_filter, :treadlife_max_filter
  attr_accessor :tire_manufacturer_id_filter, :tire_category_id_filter
  attr_accessor :exclude_generic_filter
  attr_accessor :width_filter, :ratio_filter
  # DG 7/16/15 - When coming to tire store page from a tire search, :tire_size_id, :tire_model_id, and/or :tire_manufacturer_id_filter
  #will be used for the initial tire listings filter.
  
  attr_accessor :th_customer_sql
  
  attr_accessor :promotions, :non_national_promotions
  
  composed_of :address, :class_name => "Address"
  #composed_of :account, :class_name => "Account"
  after_validation :geocode
  
  # 01/28/15 ksi We don't want to automatically register with Stripe yet...they'll have to
  # enter their banking info first.  After Beta is done and everyone is "assumed" to be an
  # eComm customer, we can revisit.
  #### after_create :register_with_stripe_with_defaults

  before_save :geocode_if_necessary

  before_save :set_social_media_ids

  has_many :tire_listings
  attr_accessible :tire_listings
  has_many :reservations, :through => :tire_listings
  has_one :cl_template
  has_one :branding
  has_many :asset_usages
  has_many :storefront_assets, :through => :asset_usages, :source => :asset, :conditions => {"asset_usages.usage_name" => "Storefront"}
  has_many :promotion_assets, :through => :asset_usages, :source => :asset, :conditions => {"asset_usages.usage_name" => "Promotions"}
  has_many :orders, :through => :tire_listings
  belongs_to :account
  geocoded_by :real_address
  reverse_geocoded_by :latitude, :longitude
  accepts_nested_attributes_for :branding
  before_validation :validate_phone
  validates_presence_of :address1, :message => 'You must enter an address'
  validates_presence_of :city, :message => 'You must enter a city'
  validates_presence_of :name, :message => 'You must enter a store name'
  validates_length_of :zipcode, :presence => true, :minimum => 5, :message => 'You must enter a zipcode'
  validates_length_of :phone, :presence => true, :maximum => 12, :minimum => 10
  validates_length_of :text_phone, :presence => true, :maximum => 10, :minimum => 10, :if => :send_text
  validates :domain.downcase, :exclusion=> { :in => %w(www beta) }, :allow_blank => true, :allow_nil => true
  validates_uniqueness_of :domain, :allow_blank => true, :allow_nil => true
  validate :valid_domain

  before_destroy { |store| TireListing.destroy_all "tire_store_id = #{store.id}" }
  before_destroy { |store| AssetUsage.destroy_all "tire_store_id = #{store.id}" }
  before_destroy { |store| Branding.destroy_all "tire_store_id = #{store.id}" }
  before_destroy { |store| ClTemplate.destroy_all "tire_store_id = #{store.id}" }
  before_destroy { |store| GenericTireListing.destroy_all "tire_store_id = #{store.id}" }
  before_destroy { |store| TireStoresDistributor.destroy_all "tire_store_id = #{store.id}" }
  before_destroy { |store| TireStoreWarehouse.destroy_all "tire_store_id = #{store.id}"}
  before_destroy { |store| TireStoreWarehouseTier.destroy_all "tire_store_id = #{store.id}"}

  scope "can_offer_promotion_for_tire_manufacturer_id", lambda { |value| where("authorized_promotion_tire_manufacturer_ids @> (? => ?)", value.to_s, "tire_manufacturer_id") }

  has_enum_field :status, status_array()

  def initialize(attributes = {})
    attributes = {} if attributes.nil?
    result = super(attributes.except(*Offering.store_offering_attributes).except(*Offering.store_services_attributes).except(:short_description))
    set_offering_and_service_properties(attributes)
    return result
  end

  def update_attributes(attributes = {})
    attributes = {} if attributes.nil?
    result = super(attributes.except(*Offering.store_offering_attributes).except(*Offering.store_services_attributes).except(:short_description))
    set_offering_and_service_properties(attributes)
    return result
  end

  def set_offering_and_service_properties(attributes)
    attributes.each do |att, val|
      if Offering.is_valid_store_offering_property(att) || Offering.is_valid_service_offering_property(att) || att == :short_description
        self.send("#{att}=", val)
      end
    end    
  end

  def can_offer_national_promotion?(promo)
    return false if !promo
    return false if promo.promo_level != "N"
    return false if self.authorized_promotion_tire_manufacturer_ids.nil? || self.authorized_promotion_tire_manufacturer_ids.size == 0

    return (self.authorized_promotion_tire_manufacturer_ids[promo.tire_manufacturer_id.to_s] == "tire_manufacturer_id")
  end

  def next_available_appt_date_and_time(from_time=Time.now)
    proposed_time = from_time + (self.min_appt_leadtime_hrs).hours

    # if it's less than 5 past the hour, we'll call it "in the window".  Otherwise we need to round up
    # to the next hour
    if proposed_time.min < 5
      proposed_day = Date.new(proposed_time.year, proposed_time.month, proposed_time.day)
      proposed_hour = proposed_time.hour
    else
      proposed_time = proposed_time + 1.hour
      proposed_day = Date.new(proposed_time.year, proposed_time.month, proposed_time.day)
      proposed_hour = proposed_time.hour
    end

    # now let's see if our proposed time is after our close time...if so, find the next open
    # time.
    if self.is_store_open_on_day_at_time?(proposed_day.wday, "#{proposed_hour}:00")
      return proposed_day, proposed_hour
    else
      # find next open time...
      next_day = proposed_day + 1.day 
      while (self.day_is_closed?(next_day))
        next_day = proposed_day + 1.day
      end

      next_hour = self.get_weekday_open(Date::DAYNAMES[next_day.wday].downcase)

    end
  end

  def open_hours_array_for_next_week
    
  end

  def tire_types
    sResult = "New & Used"

    if used_tirelistings.count == 0 && new_tirelistings.count > 0
      sResult = "New"
    end

    return sResult
  end

  def realtime_quote_distributors
    result = []
    begin
      Distributor.all.each do |dist|
        xref_rec = TireStoresDistributor.find_by_tire_store_id_and_distributor_id(self.id, dist.id)
        if xref_rec
          result << dist.id.to_s
        end
      end
    rescue
      return []
    end

    return result
  end

  ################################################################
  def stripe_receive_method
    self.financial_info['stripe_receive_method']
  end

  def stripe_receive_method=(receive_method)
    if receive_method.blank?
      self.destroy_key(:financial_info, :stripe_receive_method)
    else
      self.financial_info['stripe_receive_method'] = receive_method
    end
  end

  def stripe_tos_accept_date
    self.financial_info['stripe_tos_accept_date']
  end

  def stripe_tos_accept_date=(accept_date)
    if accept_date.blank?
      self.destroy_key(:financial_info, :stripe_tos_accept_date)
    else
      self.financial_info['stripe_tos_accept_date'] = accept_date 
    end
  end

  def stripe_tos_accepted
    if self.financial_info['stripe_tos_accepted'].nil?
      return false
    else
      return true 
    end
  end

  def stripe_tos_accepted=(accepted)
    if accepted.nil?
      self.destroy_key(:financial_info, :stripe_tos_accepted)
    else
      begin
        if accepted.to_bool == true 
          self.financial_info['stripe_tos_accepted'] = true 
        else
          self.destroy_key(:financial_info, :stripe_tos_accepted)
        end
      rescue
        self.destroy_key(:financial_info, :stripe_tos_accepted)
      end
    end
  end

  def stripe_account_id
    self.financial_info['stripe_account_id']
  end

  def stripe_account_id=(stripe_account_id)
    if stripe_account_id.blank?
      self.destroy_key(:financial_info, :stripe_account_id)
    else
      self.financial_info['stripe_account_id'] = stripe_account_id
    end
  end

  def stripe_secret_key
    self.financial_info['stripe_secret_key']
  end

  def stripe_secret_key=(key)
    if key.blank?
      self.destroy_key(:financial_info, :stripe_secret_key)
    else
      self.financial_info['stripe_secret_key'] = key
    end
  end

  def stripe_publishable_key
    self.financial_info['stripe_publishable_key']
  end

  def stripe_publishable_key=(key)
    if key.blank?
      self.destroy_key(:financial_info, :stripe_publishable_key)
    else
      self.financial_info['stripe_publishable_key'] = key
    end
  end

  def stripe_recipient_id
    self.financial_info['stripe_recipient_id']
  end

  def stripe_recipient_id=(recipient_id)
    if recipient_id.blank?
      self.destroy_key(:financial_info, :stripe_recipient_id)
    else
      self.financial_info['stripe_recipient_id'] = recipient_id
    end
  end

  def stripe_token
    self.financial_info['stripe_token']
  end

  def stripe_token=(token)
    if token.blank?
      self.destroy_key(:financial_info, :stripe_token)
    else
      self.financial_info['stripe_token'] = token
    end
  end  

  def validate_stripe_id
    if self.stripe_recipient_id && self.stripe_recipient_id.length > 0
      begin
        @customer = self.stripe_recipient_record
        if @customer.nil?
          stripe_recipient_id = ""
          self.update_attribute(:financial_info, self.financial_info)
          false
        else
          true
        end
      rescue Stripe::InvalidRequestError => e 
        # bad customer number, erase what we have
        puts "Stripe Error: #{e.to_s}"
        stripe_recipient_id = ""
        self.update_attribute(:financial_info, self.financial_info)
        false
      rescue Exception => e 
        puts "Generic Error: #{e.to_s}"
        # generic exception, ignore
        false
      end
    else
      false
    end
  end

  def validate_stripe_account_id
    if self.stripe_account_id && self.stripe_account_id.length > 0
      begin
        @account = self.stripe_account_record
        if @account.nil?
          stripe_account_id = ""
          self.update_attribute(:financial_info, self.financial_info)
          false
        else
          true
        end
      rescue Stripe::InvalidRequestError => e 
        # bad customer number, erase what we have
        puts "Stripe Error: #{e.to_s}"
        stripe_account_id = ""
        self.update_attribute(:financial_info, self.financial_info)
        false
      rescue Exception => e 
        puts "Generic Error: #{e.to_s}"
        # generic exception, ignore
        false
      end
    else
      false
    end
  end

  def register_with_stripe_as_managed_account_bank_account(entity_name=self.name, type="corporation", 
            tax_id="", bank_account_token="")
    if !self.validate_stripe_account_id
      begin
        @account = Stripe::Account.create(
          :managed => true,
          :country => "US",
          :email => self.account.billing_email,
          :business_name => entity_name, # self.name,
          #:bank_account => {"country" => "US", "currency" => "usd", 
          #                  "routing_number" => routing_number, 
          #                  "account_number" => account_number},
          :bank_account => bank_account_token,
          :default_currency => "usd",
          :legal_entity => {"type" => type, 
                            "address" => {"line1" => self.address1,
                                          "line2" => self.address2,
                                          "city" => self.city,
                                          "state" => self.state,
                                          "postal_code" => self.zipcode,
                                          "country" => "US"},
                            "business_name" => self.name,
                            "business_tax_id" => tax_id},
          #:routing_number => routing_number, # "110000000",
          #:account_number => account_number, # "000123456789",
          :metadata => {"tire_store_id" => "#{self.id}", "account_id" => "#{self.account_id}"}
        )
        if @account
          self.stripe_account_id = @account.id
          self.stripe_secret_key = @account.keys.secret
          self.stripe_publishable_key = @account.keys.publishable
          self.stripe_token = bank_account_token
          self.update_attribute(:financial_info, self.financial_info)
        else
          puts "No stripe id - could not register as recipient"         
        end
      end
    end
  end  

  def update_stripe_recipient_data_bank_account(entity_name, type, tax_id, bank_account_token)
    if false 
      recipient = get_stripe_recipient_record
      if !recipient
        entity_name = self.name if entity_name.blank?
        type = "corporation" if type.blank?
        register_with_stripe_as_recipient(entity_name, type, tax_id)
        recipient = get_stripe_recipient_record
      end

      if !recipient.nil?
        recipient.name = entity_name if !entity_name.blank? && entity_name != recipient.name
        recipient.type = type if !type.blank? && type != recipient.type && recipient.type.blank?
        recipient.tax_id = tax_id if !tax_id.blank?
        recipient.bank_account = bank_account_token
        recipient.save

        self.stripe_receive_method = "bank"
        self.update_attribute(:financial_info, self.financial_info)    
      end
    else
      account = get_stripe_account_record
      if !account
        entity_name = self.name if entity_name.blank?
        type = "corporation" if type.blank?
        register_with_stripe_as_managed_account_bank_account(entity_name, type, tax_id, bank_account_token)
        account = get_stripe_account_record
      else
        account.business_name = entity_name if !entity_name.blank? && entity_name != account.business_name
        #account.business_url = 
        #account.support_phone = 
        account.bank_account = bank_account_token
        #account.tos_acceptance = {"date" => "", "ip" => "",
        #                          "user_agent" => ""}
        account.save
      end
    end
  end

  def update_stripe_recipient_data_debit_card(entity_name, type, tax_id, card_token)
    # you cannot use debit cards with managed accounts
    update_stripe_recipient_data_bank_account(entity_name, type, tax_id, card_token)
    return

    recipient = get_stripe_recipient_record
    if !recipient
      entity_name = self.name if entity_name.blank?
      type = "corporation" if type.blank?
      register_with_stripe_as_recipient(entity_name, type, tax_id)
      recipient = get_stripe_recipient_record
    end

    if !recipient.nil?
      recipient.name = entity_name if !entity_name.blank? && entity_name != recipient.name
      recipient.type = type if !type.blank? && type != recipient.type && recipient.type.blank?
      recipient.tax_id = tax_id if !tax_id.blank?
      recipient.card = card_token
      recipient.save

      self.stripe_receive_method = "card"
      self.update_attribute(:financial_info, self.financial_info)    
    end
  end

  def register_with_stripe_as_recipient(entity_name=self.name, type="corporation", 
            tax_id="", routing_number="", account_number="")
    if !self.validate_stripe_id
      begin
        @recipient = Stripe::Recipient.create(
          :name => entity_name, # self.name,
          :type => type, # "corporation",
          :tax_id => tax_id, # "000000000",
          :country => "US",
          #:routing_number => routing_number, # "110000000",
          #:account_number => account_number, # "000123456789",
          :email => self.account.billing_email,
          :metadata => {"tire_store_id" => "#{self.id}", "account_id" => "#{self.account_id}"}
        )
        if @recipient
          self.stripe_recipient_id = @recipient.id
          self.update_attribute(:financial_info, self.financial_info)            
        else
          puts "No stripe id - could not register as recipient"         
        end
      end
    end
  end

  def delete_from_stripe
    cu = get_stripe_customer_record
    if cu
      cu.delete
    end
  end

  def delay_register_with_stripe
    self.delay.register_with_stripe_as_recipient
  end

  def register_with_stripe_with_defaults
    register_with_stripe_as_recipient()
  end

  def stripe_recipient_record
    @stripe_recipient_record ||= get_stripe_recipient_record
  end

  def stripe_account_record
    @stripe_account_record ||= get_stripe_account_record
  end

  def delete_from_stripe
    cu = get_stripe_recipient_record
    if cu
      cu.delete
    end
  end

  def get_stripe_recipient_record
    result = nil

    if self.stripe_recipient_id && self.stripe_recipient_id.length > 0
      begin
        result = Stripe::Recipient.retrieve(self.stripe_recipient_id)
      rescue Exception => e 
        result = nil
      end
    end

    return result
  end

  def get_stripe_account_record
    result = nil

    if self.stripe_account_id && self.stripe_account_id.length > 0
      begin
        result = Stripe::Account.retrieve(self.stripe_account_id)
      rescue Exception => e 
        puts "Exception: #{e.to_s}"
        result = nil
      end
    end

    return result
  end

  def can_do_ecomm?
    if false
      r = get_stripe_recipient_record
      if r.nil?
        return false
      else
        if r.active_account.nil?
          return false
        else
          return true
        end
      end
    else
      a = get_stripe_account_record
      if a.nil?
        return false
      else
        if a.bank_accounts.total_count <= 0
          return false
        else
          return true
        end
      end
    end
  end

  def set_social_media_ids
    if google_place_id.blank?
      set_google_place_id

      # now set the hours based on what google says
      if self.google_place_record
        # first let's make every day closed since closed days don't show here
        ar_days = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]

        ar_days.each do |day|
          self.google_properties["#{day}_open"] = self.google_properties["#{day}_close"] = " "
        end

        self.google_place_record.opening_hours["periods"].each do |p|
          # first process close time
          day_num = p["close"]["day"] - 1 # Monday=1, Sunday=7
          close_time = p["close"]["time"]
          set_weekday_close(ar_days[day_num], close_time.insert(2, ":"))

          # now process open time
          day_num = p["open"]["day"] - 1 # Monday=1, Sunday=7
          open_time = p["open"]["time"]
          set_weekday_open(ar_days[day_num], open_time.insert(2, ":"))
        end
      end
    end
    if yelp_customer_id.blank?
      set_yelp_customer_id
    end
  end


  ################################################################
  def yelp_customer_id
    self.google_properties['yelp_customer_id']
  end

  def yelp_customer_id=(cust_id)
    if cust_id.blank?
      self.destroy_key(:google_properties, :yelp_customer_id)
    else
      self.google_properties['yelp_customer_id'] = cust_id 
    end
  end

  def get_yelp_matches(address, filter, distance)
    bounding_box = { 
      sw_latitude: self.latitude - distance,
      sw_longitude: self.longitude - distance,
      ne_latitude: self.latitude + distance,
      ne_longitude: self.longitude + distance
    }

    params = { term: '', limit: 10, category_filter: filter}

    if true 
      response = Yelp.client.search_by_bounding_box(bounding_box, params, {lang: 'en'})
    else
      response = Yelp.client.search(address, params, {lang: 'en'})
    end
    return response.businesses
  end

  def set_google_place_id
    confidence = FuzzyStringMatch::JaroWinkler.create(:pure)
    @client = GooglePlaces::Client.new(google_places_api_key())

    ar_possibilities = []

    if self.latitude.blank? || self.latitude == 0.0 || self.longitude.blank? || 
      self.longitude == 0.0 || self.private_seller || !self.google_place_id.blank? ||
      self.google_place_id == "cannot_find"
      return nil, nil
    else
      @businesses = @client.spots(self.latitude, self.longitude, :name => self.name)
      puts "*******************************************************************************"

      puts "#{self.name} #{self.full_address}"
      if @businesses.size == 0
        puts "No match found in original search..."

        # first, let's put our store's address in "standard google format"
        found = false
        @businesses = @client.spots_by_query(self.full_address)
        if @businesses.size > 0
          @standard_address = @businesses.first.formatted_address.gsub(/,\ USA/, '').gsub(/,\ United\ States/, '')
          puts "Standardized address is #{@standard_address}"

          @businesses = @client.spots_by_query("Tires near #{self.full_address}")
          @businesses.each do |t|
            @bus_standard_address = t.formatted_address.gsub(/,\ USA/, '').gsub(/,\ United\ States/, '')
            if @standard_address.downcase == @bus_standard_address.downcase
              puts "I **** think **** I have a match...#{t.name} #{t.place_id}"
              ar_possibilities << t
              found = true 
            else
              puts "no match - #{@bus_standard_address} #{t.name} #{t.place_id}"
            end
          end
        end

        if !found
          #@businesses = @client.spots_by_query("#{self.name} #{self.full_address} (#{self.latitude}, #{self.longitude})")
          @businesses = @client.spots_by_query("tire shop #{self.full_address}")
          if @businesses.size == 1
            puts "Might have found a match on second search...(#{@businesses[0].lat}, #{@businesses[0].lng}) #{@businesses[0].formatted_address} #{@businesses[0].name}"
            con = confidence.getDistance(self.name.downcase, @businesses[0].name.downcase)
            if con > 0.8
              puts "\t\tMatch on first! #{@businesses[0].name} #{con}"
              self.google_place_id = @businesses[0].place_id
              save
              return nil, nil
            else
              ar_possibilities << @businesses.first
            end
          elsif @businesses.size == 0
            puts "\t\tNo matches on second search"
          else
            # multiple 
            puts "\t\tMultiple matches on second search..."
            puts "Checking @businesses[0] - #{@businesses[0].name} #{@businesses[0].formatted_address}"
            con = confidence.getDistance(self.name.downcase, @businesses[0].name.downcase)
            if con > 0.8
              puts "\t\tFirst record of second search looks good! #{@businesses[0].name} #{con}"
              self.google_place_id = @businesses[0].place_id
              save
              return nil, nil
            else
              @businesses.each do |t|
                ar_possibilities << t 
              end
            end
          end
        end
      elsif @businesses.size == 1
        con = confidence.getDistance(self.name.downcase, @businesses[0].name.downcase)
        if con > 0.75
          puts "\t\tMatch on first! #{@businesses[0].name} #{con}"
          self.google_place_id = @businesses[0].place_id
          save
          return nil, nil
        else
          ar_possibilities << @businesses.first
          puts "\t\tBad first match....#{@businesses[0].name} #{con}"
        end
      else
        puts "Multiple original matches for #{self.name}"
        @businesses.each do |b|
          con = confidence.getDistance(self.name.downcase, b.name.downcase)
          if con > 0.8
            puts "\tI think I got one - #{self.name} & #{b.name.downcase}"
            ##self.yelp_customer_id = b.id
            ##save
          else
            puts "\tOn original search, I don't like the match for #{self.name} & #{b.name} (#{con})"
          end
          ar_possibilities << b
        end
      end

      puts "*******************************************************************************"

      return self, ar_possibilities
    end
  end

  def set_yelp_customer_id
    confidence = FuzzyStringMatch::JaroWinkler.create(:pure)

    if self.latitude.blank? || self.latitude == 0.0 || self.longitude.blank? || 
      self.longitude == 0.0 || self.private_seller || !self.yelp_customer_id.blank?
      return
    else
      businesses = get_yelp_matches(self.full_address, 'tires', 0.0010)

      puts "*******************************************************************************"

      puts "#{self.name} #{self.full_address}"
      if businesses.size == 0 
        # no matches at all...let's try a different term
        businesses = get_yelp_matches(self.full_address, '', 0.0010)

        puts "No original match for #{self.name}, but with no filter I got #{businesses.size}"

        if businesses.size == 0
          businesses = get_yelp_matches(self.full_address, 'tires', 0.0025)
          if businesses.size > 0
            businesses.each do |b|
              con = confidence.getDistance(self.name.downcase, b.name.downcase)
              if con > 0.8
                puts "\t\tI think I got one - #{self.name} & #{b.name}"
                self.yelp_customer_id = b.id
                save
              else
                puts "\t\tHmmmm....bad confidence for #{self.name} & #{b.name}"
              end
            end
          else
            puts "\tStill no matches..."
          end
        else
          businesses.each do |b|
            con = confidence.getDistance(self.name.downcase, b.name.downcase)
            if con > 0.8
              puts "\tI think I got one - #{self.name} & #{b.name}"
              self.yelp_customer_id = b.id
              save
            else
              puts "\tHmmmm....bad confidence for #{self.name} & #{b.name}"
            end
          end
        end
      elsif businesses.size == 1
        con = confidence.getDistance(self.name.downcase, businesses[0].name.downcase)
        if con > 0.8
          puts "First Match!: #{businesses[0].name} (#{self.name}) #{con}"
          self.yelp_customer_id = businesses[0].id
          save
        else
          puts "Not a match: #{businesses[0].name} (#{self.name}) #{con}"
        end
      else
        puts "Multiple original matches for #{self.name}"
        businesses.each do |b|
          con = confidence.getDistance(self.name.downcase, b.name.downcase)
          if con > 0.8
            puts "\tI think I got one - #{self.name} & #{b.name.downcase}"
            self.yelp_customer_id = b.id
            save
          else
            puts "\tOn original search, I don't like the match for #{self.name} & #{b.name} (#{con})"
          end
        end
      end

      puts "*******************************************************************************"
    end
  end

  def self.fix_all_24_hours
    TireStore.all.each do |t|
      if t.open_all_day_array == [false, false, false, false, false, false, true]
        t.google_properties["sunday_open"] = " "
        t.google_properties["sunday_close"] = " "
        t.phone = "7705551212" if t.phone.blank?
        if !t.save
          puts "Failed to save: (phone is #{t.phone})"
          t.errors.each do |e, r|
            puts "#{e} - #{r}"
          end
        else
          puts "ok"
        end
      elsif t.open_all_day_array == [true, false, false, false, false, false, false]
        t.google_properties["sunday_open"] = " "
        t.google_properties["sunday_close"] = " "
        t.phone = "7705551212" if t.phone.blank?
        if !t.save
          puts "Failed to save: (phone is #{t.phone})"
          t.errors.each do |e, r|
            puts "#{e} - #{r}"
          end
        else
          puts "ok"
        end
      elsif t.open_all_day_array == [true, true, true, true, true, true, true]
        t.google_properties["sunday_open"] = " "
        t.google_properties["sunday_close"] = " "
        t.monday_open = t.tuesday_open = t.wednesday_open = t.thursday_open = t.friday_open = t.saturday_open = "08:00"
        t.monday_close = t.tuesday_close = t.wednesday_close = t.thursday_close = t.friday_close = t.saturday_close = "18:00"
        t.phone = "7705551212" if t.phone.blank?
        if !t.save
          puts "Failed to save: (phone is #{t.phone})"
          t.errors.each do |e, r|
            puts "#{e} - #{r}"
          end
        else
          puts "ok"
        end
      elsif t.monday_close == "08:00" && t.tuesday_close == "08:00"
        t.monday_close = t.tuesday_close = t.wednesday_close = t.thursday_close = t.friday_close = t.saturday_close = "18:00"
        t.phone = "7705551212" if t.phone.blank?
        if !t.save
          puts "Failed to save: (phone is #{t.phone})"
          t.errors.each do |e, r|
            puts "#{e} - #{r}"
          end
        else
          puts "ok"
        end
      end
    end
  end

  def self.set_all_yelp_customer_ids
    #TireStore.find(:all).each do |t|
    TireStore.where("private_seller = FALSE AND (google_properties IS NULL OR EXIST(google_properties, 'yelp_customer_id')=FALSE)").each do |t|
      t.set_yelp_customer_id
    end
  end

  def self.set_all_google_place_ids
    #TireStore.find(:all).each do |t|
    all_stores = []
    TireStore.where("private_seller = FALSE AND (google_properties IS NULL OR EXIST(google_properties, 'google_place_id')=FALSE)").each do |t|
      all_stores << t.set_google_place_id unless all_stores.size > 50
    end

    ar_email = []

    all_stores.each do |t, ar_possibilities|
      if !t.nil?
        ar_email << "  "
        ar_email << "  "
        ar_email << "  "
        ar_email << "#{t.id} #{t.name}"
        ar_email << "#{t.full_address}"
        ar_email << "----------------------------"
        ar_possibilities.each do |place|
          ar_email << "   #{place.name} #{place.place_id}"
          ar_email << "      #{place.formatted_address}"
          ar_email << "      http://#{ActionMailer::Base.default_url_options[:host]}/tire_stores/set_place_id?tire_store_id=#{t.id}&place_id=#{place.place_id}"
        end
        ar_email << "      To set as 'not found', click:"
        ar_email << "      http://#{ActionMailer::Base.default_url_options[:host]}/tire_stores/set_place_id?tire_store_id=#{t.id}&place_id=cannot_find"
        ar_email << "  "
        ar_email << "  "
        ar_email << "  "
      end
    end

    if all_stores.size > 0
      return ar_email
    else
      return nil
    end
  end

  def self.update_google_data_older_than(num_hours)
    total_updated = 0
    total_not_updated = 0

    stores_to_update = TireStore.where("(EXIST(google_properties, 'google_place_id')=TRUE) AND ((NOT EXIST(google_properties, 'google_rating_updated_at')) OR (google_properties -> 'google_rating_updated_at')::date < (now() - INTERVAL '#{num_hours} HOUR'))")
    stores_to_update.each do |t|
      google_place_record = t.google_place_record
      if !google_place_record.nil?
        save_record = false
        if t.google_rating_updated_at.nil?
          t.google_rating_updated_at = Time.now 
          save_record = true 
        end

        if t.google_rating != google_place_record.rating 
          t.google_rating = google_place_record.rating
          save_record = true 
        end

        if t.google_reviews_count != google_place_record.user_ratings_total 
          t.google_reviews_count = google_place_record.user_ratings_total
          save_record = true 
        end

        # currently there is no API call to get the google image
        if false
          if t.google_rating_img_url |= google_place_record.rating_img_url 
            t.google_rating_img_url = google_place_record.rating_img_url
            save_record = true 
          end
        end

        if save_record
          total_updated += 1
          t.save
        else
          total_not_updated += 1
        end
      else
        total_not_updated += 1
      end
    end

    return total_updated, total_not_updated
  end

  def self.update_yelp_data_older_than(num_hours)
    stores_to_update = TireStore.where("(EXIST(google_properties, 'yelp_customer_id')=TRUE) AND ((NOT EXIST(google_properties, 'yelp_rating_updated_at')) OR (google_properties -> 'yelp_rating_updated_at')::date < (now() - INTERVAL '#{num_hours} HOUR'))")
    stores_to_update.each do |t|
      yelp_record = t.yelp_customer_record
      if !yelp_record.nil?
        save_record = false
        if t.yelp_rating_updated_at.nil?
          t.yelp_rating_updated_at = Time.now 
          save_record = true 
        end

        if t.yelp_rating != yelp_record.rating 
          t.yelp_rating = yelp_record.rating
          save_record = true 
        end

        if t.yelp_rating_img_url |= yelp_record.rating_img_url 
          t.yelp_rating_img_url = yelp_record.rating_img_url
          save_record = true 
        end

        if save_record
          t.save 
        end
      end
    end
  end

  def order_count_ytd
    @ytd_orders ||= get_orders_since(Time.now.beginning_of_year)
    return @ytd_orders.count
  end

  def order_amount_ytd
    @ytd_orders ||= get_orders_since(Time.now.beginning_of_year)
    return @ytd_orders.collect{|o| o.total_order_price}.sum.to_s.to_f.round(2)
  end

  def order_revenue_ytd
    @ytd_orders ||= get_orders_since(Time.now.beginning_of_year)
    return @ytd_orders.collect{|o| o.transfer_amount}.sum.to_s.to_f.round(2)
  end

  def order_count_mtd
    @mtd_orders ||= get_orders_since(Time.now.beginning_of_month)
    return @mtd_orders.count
  end

  def order_amount_mtd
    @mtd_orders ||= get_orders_since(Time.now.beginning_of_month)
    return @mtd_orders.collect{|o| o.total_order_price}.sum.to_s.to_f.round(2)
  end

  def order_revenue_mtd
    @mtd_orders ||= get_orders_since(Time.now.beginning_of_month)
    return @mtd_orders.collect{|o| o.transfer_amount}.sum.to_s.to_f.round(2)
  end

  def order_count_wtd
    @wtd_orders ||= get_orders_since(Time.now.beginning_of_week)
    return @wtd_orders.count
  end

  def order_amount_wtd
    @wtd_orders ||= get_orders_since(Time.now.beginning_of_week)
    return @wtd_orders.collect{|o| o.total_order_price}.sum.to_s.to_f.round(2)
  end

  def order_revenue_wtd
    @wtd_orders ||= get_orders_since(Time.now.beginning_of_week)
    return @wtd_orders.collect{|o| o.transfer_amount}.sum.to_s.to_f.round(2)
  end

  def order_count_by_year
  end

  def order_amount_by_year
  end

  def order_revenue_by_year
  end

  def order_count_by_month
  end

  def order_amount_by_month
  end

  def order_revenue_by_month
  end

  def order_count_by_week
  end

  def order_amount_by_week
  end

  def order_revenue_by_week
  end

  def get_orders_since(dt_since)
    Order.joins('LEFT OUTER JOIN tire_listings ON tire_listings.id = orders.tire_listing_id').where('tire_listings.tire_store_id = ? and orders.created_at >= ? and orders.status < ?', self.id, dt_since, order_status_array[:created])
  end

  def get_order_history(dt_since, selector)
    sql =  "select #{selector} as group_field,
            count(*) as order_count,
            sum(th_user_fee) as order_user_fee, 
            sum(sales_tax_collected) as order_sales_tax, 
            sum(th_processing_fee) as order_th_processing_fee,
            sum(tire_quantity) as order_total_tires,
            sum(transfer_amount) as order_total
            from orders
            inner join tire_listings on tire_listings.id = orders.tire_listing_id
            inner join tire_stores on tire_stores.id = tire_listings.tire_store_id
            where tire_stores.id = #{self.id}
            and orders.status < #{order_status_array[:created]}
            and orders.created_at >= '#{dt_since}'
            and orders.created_at <= '#{Time.now}'
            group by #{selector} 
            order by #{selector}"
    return ActiveRecord::Base.connection.execute(sql).to_a
  end

  def get_weekly_order_history(dt_since='2000-01-01')
    return @weekly_history ||= get_order_history(dt_since, "EXTRACT(YEAR from orders.created_at) * 100 + EXTRACT(WEEK from orders.created_at)")
  end

  def get_monthly_order_history(dt_since='2000-01-01')
    return @monthly_history ||= get_order_history(dt_since, "EXTRACT(YEAR from orders.created_at) * 100 + EXTRACT(MONTH from orders.created_at)")
  end

  def get_yearly_order_history(dt_since='2000-01-01')
    return @yearly_history ||= get_order_history(dt_since, "EXTRACT(YEAR from orders.created_at)")
  end

  def get_yelp_customer_record
    if self.yelp_customer_id.blank?
      return nil 
    else
      return Yelp.client.business(yelp_customer_id)
    end
  end

  def allow_google_reviews
    if self.google_place_id.blank? || self.google_place_id == "cannot_find"
      return false
    else
      return true 
    end
  end

  def store_review_link
    if self.allow_google_reviews
      "/tire_stores/write_review?tire_store_id=#{self.id}"
    else
      ""
    end
  end

  def get_google_place_record
    if self.google_place_id.blank? || self.google_place_id == "cannot_find"
      return nil 
    else
      begin
        return GooglePlaces::Spot.find(self.google_place_id, google_places_api_key())
      rescue
        return nil 
      end
    end
  end

  def yelp_customer_record
    @yelp_customer_record ||= get_yelp_customer_record
  end

  def google_place_record
    @google_place_record ||= get_google_place_record
  end

  def consumer_rating
    self.google_rating
  end

  def consumer_rating_count
    self.google_reviews_count
  end

  def yelp_rating
    self.google_properties['yelp_rating']
  end

  def yelp_rating=(rating)
    if rating.blank?
      self.destroy_key(:google_properties, :yelp_rating)
    else
      if rating != self.google_properties['yelp_rating']
        self.google_properties['yelp_rating'] = rating
        self.yelp_rating_updated_at = Time.now
      end
    end
  end

  def google_reviews_count
    self.google_properties['google_reviews_count']
  end

  def google_reviews_count=(reviews_count)
    if reviews_count.blank?
      self.destroy_key(:google_properties, :google_reviews_count)
    else
      if reviews_count != self.google_properties['google_reviews_count']
        self.google_properties['google_reviews_count'] = reviews_count
        self.google_rating_updated_at = Time.now
      end
    end
  end  

  def google_rating
    self.google_properties['google_rating']
  end

  def google_rating=(rating)
    if rating.blank?
      self.destroy_key(:google_properties, :google_rating)
    else
      if rating != self.google_properties['google_rating']
        self.google_properties['google_rating'] = rating
        self.google_rating_updated_at = Time.now
      end
    end
  end

  def yelp_rating_updated_at
    self.google_properties['yelp_rating_updated_at']
  end

  def yelp_rating_updated_at=(upd_at)
    if upd_at.blank?
      self.destroy_key(:google_properties, :yelp_rating_updated_at)
    else
      self.google_properties['yelp_rating_updated_at'] = upd_at
    end
  end

  def google_rating_updated_at
    self.google_properties['google_rating_updated_at']
  end

  def google_rating_updated_at=(upd_at)
    if upd_at.blank?
      self.destroy_key(:google_properties, :google_rating_updated_at)
    else
      self.google_properties['google_rating_updated_at'] = upd_at
    end
  end

  def yelp_rating_img_url
    self.google_properties['yelp_rating_img_url']
  end

  def yelp_rating_img_url=(img_url)
    if img_url.blank?
      self.destroy_key(:google_properties, :img_url)
    else
      self.google_properties['yelp_rating_img_url'] = img_url
    end
  end

  def google_rating_img_url
    self.google_properties['google_rating_img_url']
  end

  def google_rating_img_url=(img_url)
    if img_url.blank?
      self.destroy_key(:google_properties, :google_url)
    else
      self.google_properties['google_rating_img_url'] = img_url
    end
  end

  def yelp_rating_live
    y = self.yelp_customer_record
    if y 
      return y.rating 
    else
      return nil 
    end
  end

  def yelp_mobile_url
    y = self.yelp_customer_record
    if y
      return y.mobile_url 
    else
      return nil 
    end
  end

  def yelp_rating_img_url_live
    y = self.yelp_customer_record
    if y
      return y.rating_img_url
    else
      return nil 
    end
  end

  def yelp_review_count
    y = self.yelp_customer_record
    if y
      return y.review_count
    else
      return nil 
    end
  end

  def yelp_snippet_image_url
    y = self.yelp_customer_record
    if y
      return y.snippet_image_url
    else
      return nil 
    end
  end

  def yelp_rating_img_url_small
    y = self.yelp_customer_record
    if y
      return y.rating_img_url_small
    else
      return nil 
    end
  end

  def yelp_url
    y = self.yelp_customer_record
    if y
      return y.url
    else
      return nil 
    end
  end

  def yelp_reviews
    y = self.yelp_customer_record
    if y
      return y.reviews
    else
      return nil 
    end
  end

  def yelp_snippet_text
    y = self.yelp_customer_record
    if y
      return y.snippet_text
    else
      return nil 
    end
  end

  ################################################################
  def self.find_by_google_place_id(place_id)
    result = TireStore.where("google_properties -> 'google_place_id' = '#{place_id}'")
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

  def hours_not_available?
    if sunday_open.blank? && monday_open.blank? && tuesday_open.blank? && wednesday_open.blank? &&
      thursday_open.blank? && friday_open.blank? && saturday_open.blank?
      return true
    else
      return false
    end
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

  def open_all_day_array
    result = []
    (0..6).each do |wday|
      if day_is_24_hours?(wday)
        result << true 
      else
        result << false 
      end
    end

    return result
  end

  def closed_all_day_array
    result = []
    (0..6).each do |wday|
      if day_is_closed?(wday)
        result << true 
      else
        result << false 
      end
    end

    return result
  end

  def is_closed?(start_time, end_time)
    if (start_time.blank? || end_time.blank?) && !(start_time.nil? && end_time.nil?)
      return true 
    else
      return false
    end
  end

  def is_store_open_on_day_at_time?(day_int, time_str)
    if day_is_closed?(day_int)
      return false
    elsif day_is_24_hours?(day_int)
      return true
    else
      weekday = Date::DAYNAMES[day_int].downcase
      start_time = Time.parse(get_weekday_open(weekday))
      end_time = Time.parse(get_weekday_close(weekday))
      check_time = Time.parse(time_str)

      if check_time >= start_time && check_time < end_time
        return true
      else
        return false
      end
    end
  end

  def day_is_closed?(day_int)
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

    return is_closed?(start_time, end_time)
  end


  def is_24_hours?(start_time, end_time)
    if (start_time == "00:00" && end_time == "24:00") ||
        (start_time == "00:00" && end_time == "23:59") ||
        (start_time.nil? && end_time.nil?)
      return true 
    else
      return false
    end
  end

  def day_is_24_hours?(day_int)
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

    return is_24_hours?(start_time, end_time)
  end

  def hours_as_string(day_int, format_as_today)
    if format_as_today
      sResult = "" #"Hours: Not specified"
    else
      sResult = "" # "#{Date::DAYNAMES[day_int]}: Not specified"
    end

    begin
      if !self.hours_not_available?
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
          elsif is_closed?(start_time, end_time)
            if format_as_today
              sResult = "Closed today"
            else
              sResult = "#{Date::DAYNAMES[day_int]}: Closed"
            end
          elsif is_24_hours?(start_time, end_time)
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

  def hours_array_for_date(date_to_check)
    result = []

    weekday = date_to_check.wday 

    if day_is_24_hours?(weekday)
      result = *(00..23).map{|h| [Time.parse("#{h}:00").strftime("%I:%M %P"), Time.parse("#{h}:00").strftime("%H:%M")]}
    elsif day_is_closed?(weekday)
      result = [["closed", ""]]
    else
      weekday_name = Date::DAYNAMES[weekday].downcase
      start_time = get_weekday_open(weekday_name)
      end_time = get_weekday_close(weekday_name)

      start_hour = Time.parse(start_time).hour
      end_hour = Time.parse(end_time).hour - 1

      result = *(start_hour..end_hour).map{|h| [Time.parse("#{h}:00").strftime("%I:%M %P"), Time.parse("#{h}:00").strftime("%H:%M")]}
    end

    return result
  end

  def hours_open_as_string_array
    result = []

    (0..6).each do |wday|
      result << hours_as_string(wday, false)
    end

    return result
  end  
  ################################################################

  def add_tire_manufacturer_id_as_authorized(tire_manufacturer_id)
    self.authorized_promotion_tire_manufacturer_ids = (authorized_promotion_tire_manufacturer_ids || {}).merge(tire_manufacturer_id.to_s => "tire_manufacturer_id")
  end

  def remove_tire_manufacturer_id_from_authorized(tire_manufacturer_id)
    self.authorized_promotion_tire_manufacturer_ids = self.authorized_promotion_tire_manufacturer_ids.except(tire_manufacturer_id.to_s)
  end

  def manufacturer_names_carried
    if self.brands_carried.nil? || self.brands_carried.size == 0
      return self.account.manufacturer_names_carried
    else
      result = []
      self.brands_carried.keys.each do |k|
        if self.brands_carried[k] == "tire_manufacturer_id"
          result << TireManufacturer.find(k).name
        end
      end
      return result
    end
  end 

  def carries_tire_manufacturer?(tire_manu)
    return false if !tire_manu
    if self.brands_carried.nil? || self.brands_carried.size ==0
      return false if self.account.nil?
      return self.account.carries_tire_manufacturer(tire_manu)
    else
      return (self.brands_carried[tire_manu.id.to_s] == "tire_manufacturer_id")
    end
  end

  def carries_tire_manufacturer_id?(tire_manu_id)
    return false if !tire_manu_id

    if self.brands_carried.nil? || self.brands_carried.size == 0
      return false if self.account.nil?
      return self.account.carries_tire_manufacturer_id?(tire_manu_id)
    else
      return (self.brands_carried[tire_manu_id.to_s] == "tire_manufacturer_id")
    end
  end

  def add_tire_manufacturer_id_to_brands_carried(tire_manufacturer_id)
    self.brands_carried = (brands_carried || {}).merge(tire_manufacturer_id.to_s => "tire_manufacturer_id")
  end

  def remove_tire_manufacturer_id_from_brands_carried(tire_manufacturer_id)
    self.brands_carried = self.brands_carried.except(tire_manufacturer_id.to_s)
  end  
  
  def th_customer
    if self.id.nil? || self.account_id.nil?
      false
    elsif @th_customer_sql.nil?
      true
    else
      @th_customer_sql.to_bool
    end
  end

  STOREFRONT_COLORS.each do |h|
    attr_accessible h

    key = h[:key]
    default = h[:default]
    label = h[:label]

    define_method(key) do
      result = colors && colors[key]
      result = default if !result
      result
    end

    define_method("#{key}_default") do
      default
    end

    define_method("#{key}_label") do
      label
    end

    define_method("#{key}=") do |value|
      self.colors = (colors || {}).merge(key => value)
    end
  end

  STOREFRONT_SIZES.each do |h|
    attr_accessible h

    key = h[:key]
    default = h[:default]
    label = h[:label]
    choices = h[:choices]

    define_method(key) do
      result = colors && colors[key]
      result = default if !result
      result
    end

    define_method("#{key}_default") do
      default
    end

    define_method("#{key}_label") do
      label
    end

    define_method("#{key}_choices") do
      choices
    end

    define_method("#{key}=") do |value|
      self.colors = (colors || {}).merge(key => value)
    end
  end

  def valid_domain
    if !self.domain.nil? && self.domain.length > 0
      if website && !website.is_valid_url?
        errors.add(:base, "Invalid website domain")
      end
    end
  end

  def validate_phone
    if self.phone
      self.phone = self.phone.gsub(/\D/, '') # remove non-numeric chars
      self.text_phone = self.text_phone.gsub(/\D/, '') if self.text_phone
    end
  end

  def formatted_phone_number
    begin
      number_to_phone(self.phone, area_code: true)
    rescue
      ""
    end
  end

  def website
    "http://#{domain}.#{Rails.configuration.storefront_domain}" if domain && domain.length > 0 && Rails.configuration.storefront_domain
  end

  def to_param
    if self.private_seller?
      "#{id}"
    elsif !city.nil? && !state.nil?
      "#{id}-#{name.parameterize}-#{city.parameterize}-#{state.parameterize}"
    else
      "#{id}"
    end
  end

  def paginated_tirelistings(page_no)
    self.tire_listings.paginate(page: page_no, :per_page => 50)
  end

  def tire_listings
    @tire_listings ||= find_tirelistings
  end
  
  def mobile_tire_listings
    TireListing.limit(250).includes(:tire_size, :tire_manufacturer, :tire_model, :tire_category).where(conditions).order("is_new, created_at desc")   
  end

  def mobile_tire_listings_filtered(search_filter)
    @all_listings = TireListing.includes(:tire_size, :tire_manufacturer, :tire_model, :tire_category).where(conditions).order("is_new, created_at desc")
    # now find the ones that match our filter
    return @all_listings.find_all{|t| t.search_description_matches(search_filter)}
  end

  def has_new_and_used?
    (!private_seller? && used_tirelistings.count > 0 && new_tirelistings.count > 0)
  end

  def tirelistings_view_count(since_date = '2010-01-01')
    Impression.find(:all, :conditions => ["impressionable_type = ? AND impressionable_id = ? AND controller_name = ? and created_at >= ?", "TireStore", self.id, "tire_listings", since_date.to_date]).count
  end

  def tirestore_view_count(since_date = '2010-01-01')
    Impression.find(:all, :conditions => ["impressionable_type = ? AND impressionable_id = ? AND controller_name = ? and created_at >= ?", "TireStore", self.id, "tire_stores", since_date.to_date]).count
  end

  def tirelistings_view_count_unique(since_date = '2010-01-01')
    Impression.find(:all, :select => "DISTINCT ip_address", :conditions => ["impressionable_type = ? AND impressionable_id = ? AND controller_name = ? and created_at >= ?", "TireStore", self.id, "tire_listings", since_date.to_date]).count
  end

  def tirestore_view_count_unique(since_date = '2010-01-01')
    Impression.find(:all, :select => "DISTINCT ip_address", :conditions => ["impressionable_type = ? AND impressionable_id = ? AND controller_name = ? and created_at >= ?", "TireStore", self.id, "tire_stores", since_date.to_date]).count
  end

  def reservations_count(since_date = '2010-01-01')
    Impression.find(:all, :conditions => ["impressionable_type = ? AND impressionable_id = ? AND controller_name = ? and created_at >= ?", "TireStore", self.id, "reservations", since_date.to_date]).count
  end

  def tab_count
    if self.branding
      self.branding.tab_count
    else
      0
    end
  end

  def tabs
    if self.branding
      self.branding.tabs
    else
      []
    end
  end

  def tab_titles
    if self.branding
      self.branding.tab_titles
    else
      []
    end
  end

  def logo_url
    self.branding.logo.url if self.branding && self.branding.logo.exists?
  end

  def visible_name
    if self.private_seller?
      'Private Seller'
    else
      self.name
    end
  end

  def visible_phone
    if self.private_seller? && self.hide_phone?
      'Phone Hidden'
    else
      number_to_phone(self.phone, :area_code => true)
    end
  end

  def has_branding?
    #if account.can_use_branding?
    #  if self.branding.nil? || self.branding.expiration_date.nil?
    #    false
    #  else
    #    self.branding.expiration_date > DateTime.current
    #  end
    #else
    #  false
    #end
    
    # for now, not going to deal with custom branding
    false 
  end
  
  def cl_template
    @cl_template ||= get_template
  end
  
  def promotions
    @promotions ||= Promotion.unique_store_promotions(self, "all")
  end

  def applicable_promotions
    @applicable_promotions ||= Promotion.unique_applicable_store_promotions(self, "all")
  end
  
  def non_national_promotions
    # 10/9 use this line below if you want to include only non national promotions
    # @non_national_promotions ||= Promotion.unique_non_national_store_promotions(self, "all")
    # 10/9 use this line to include national and non-national promotions
    # return self.promotions
    # 10/9 use this line to include national and non national promotions ONLY for tires that
    # we have listings for
    return self.applicable_promotions
  end

  def get_template
    template = ClTemplate.find_by_tire_store_id(self.id)
    if template.nil?
      master_template = ClTemplate.find_by_tire_store_id(0)
      if master_template
        template = master_template.dup
        template.tire_store_id = self.id
        template.account_id = self.account_id
      end
    end
    template
  end

  def full_address
    if private_seller?
      "#{self.city}, #{self.state} #{self.zipcode}"
    else
      "#{self.address1} #{self.address2}, #{self.city}, #{self.state} #{self.zipcode}"
    end
  end

  def tire_searches
    @tiresearches ||=  find_tiresearches
  end

  def find_tiresearches
    # first part just gets a list of tire search IDs for our region in the last week.
    # in short, we can't do a geography search with group by, count(), etc. so we have to do two searches

    arSearches = TireSearch.near([self.latitude, self.longitude], 50).where("created_at >= '" + (Time.now - 7.days).to_s + "'").map(&:id)

    TireSearch.select("sizestr, tire_size_id, count(tire_size_id)").where(:id => arSearches).group("sizestr, tire_size_id").joins("inner join tire_sizes on tire_sizes.id = tire_size_id").order("count(tire_size_id) DESC")
  end

  def self.search(params)
    radius = 0
    location = keywords = ''
    location = params["Location"] if !params.nil?
    radius = params["Radius"] if !params.nil?
    keywords = params["Keywords"] if !params.nil?
    inc_private_seller = params["IncludePrivate"].to_s.to_bool if !params.nil?
    
    if params["columns"].blank?
      columns = "*, true as th_customer_sql"
    else
      columns = params["columns"]
    end

    radius = 20 if radius.to_i <= 0

    if keywords.to_s == '' and location.to_s != ''
      if inc_private_seller
        near(location, radius).find(:all, :select => columns)
      else
        near(location, radius).find(:all, :conditions => ['private_seller = false'], :select => columns)
      end
    elsif keywords.to_s != '' and location.to_s != ''
      if inc_private_seller
        near(location, radius).find(:all, :conditions => ['name ~* ?', keywords], :select => columns)         
      else
        near(location, radius).find(:all, :conditions => ['name ~* ? and private_seller = false', keywords], :select => columns) 
      end
    elsif keywords.to_s != '' and location.to_s == ''
      if inc_private_seller
        find(:all, :conditions => ['name ~* ?', keywords], :order => 'name', :select => columns)                 
      else
        find(:all, :conditions => ['name ~* ? and private_seller = false', keywords], :order => 'name', :select => columns)         
      end
    else
      if inc_private_seller
        find(:all, :select => columns)
      else
        find(:all, :conditions => ['private_seller = false'], :order => 'name', :select => columns) if keywords.to_s == '' and location.to_s == ''        
      end
    end
  end

  def phone_number_image_name
    Digest::SHA1.hexdigest("--#{@id}--#{visible_phone}--")
  end

  def listings_sortorder
    self.sort_order = SortOrder::SORT_BY_UPDATED_DESC if self.sort_order.nil?

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
      "tire_listings.distance ASC"
    when SortOrder::SORT_BY_DISTANCE_DESC
      "tire_listings.distance DESC"
    when SortOrder::SORT_BY_COST_PER_TIRE_ASC
      "CASE WHEN tire_listings.is_new = true THEN (tire_listings.price::float / 100) ELSE (tire_listings.price::float / (100 * tire_listings.quantity)) END ASC"
    when SortOrder::SORT_BY_COST_PER_TIRE_DESC
      "CASE WHEN tire_listings.is_new = true THEN (tire_listings.price::float / 100) ELSE (tire_listings.price::float / (100 * tire_listings.quantity)) END DESC"
    else
      "tire_listings.updated_at DESC"
    end
  end

  #def find_tirelistings
  #  TireListing.limit(400).includes(:tire_size, :tire_manufacturer, :tire_model, :tire_category).find(:all, :conditions => conditions, :order => listings_sortorder())
  #end

  def find_tirelistings
    #TireListing.includes(:tire_size, :tire_manufacturer, :tire_model, :tire_category).find(:all, :conditions => conditions, :select => "tire_listings.*, CASE WHEN tire_listings.is_new = true THEN (tire_listings.price::float / 100) ELSE (tire_listings.price::float / (100 * tire_listings.quantity)) END AS cost_per_tire", :order => listings_sortorder)
    TireListing.includes(:tire_size, :tire_manufacturer, :tire_model, :tire_category).where(conditions).order(listings_sortorder)
  end

  def used_tirelistings
    @used_tirelistings ||= begin
      c = conditions
      if c.size > 0
        c[0] += ' AND is_new = ?'
      else
        c << 'is_new = ?'
      end
      c << false
      TireListing.limit(400).includes(:tire_size, :tire_manufacturer, :tire_model, :tire_category).find(:all, :conditions => c, :order => listings_sortorder)
    end
  end

  def new_tirelistings
    @new_tirelistings ||= begin
      c = conditions
      if c.size > 0
        c[0] += ' AND is_new = ?'
      else
        c << 'is_new = ?'
      end
      c << true
      TireListing.limit(400).includes(:tire_size, :tire_manufacturer, :tire_model, :tire_category).find(:all, :conditions => c, :order => listings_sortorder)
    end
  end

  def treadhunter_domain(dom)
    "#{dom.downcase}.tread-hunter.com" if dom && dom.size > 0
  end

  def geocode_if_necessary
    # if we already tried to geocode using "real_address" and failed, we need to try using zipcode or city/state
    if self.latitude.blank? || self.latitude == 0.0 || self.longitude.blank? || self.longitude == 0.0
      begin
        g = Geocoder.search("#{self.zipcode}")
        if g.size > 0
          self.latitude, self.longitude = g.first.coordinates
        end
      rescue
      end
    end
    
    if self.latitude.blank? || self.latitude == 0.0 || self.longitude.blank? || self.longitude == 0.0
      begin
        g = Geocoder.search("#{self.city}, #{self.state}")
        if g.size > 0
          self.latitude, self.longitude = g.first.coordinates
        end
      rescue
      end
    end
  end

  def import_tci_data
    tci = TCIInterface.new
    tci.delay.import_tire_store_data(self)
  end

  def confirmed_appointments
    @confirmed_appointments ||= get_confirmed_appointments_count
  end

  def unconfirmed_appointments
    @unconfirmed_appointments ||= appointments.size - confirmed_appointments
  end

  def get_confirmed_appointments_count
    confirmed = 0

    appointments.each do |a|
      if a.confirmed_flag
        confirmed += 1
      end
    end

    return confirmed
  end

  def top_tire_listings
    @top_tire_listings ||= TireListing.find(:all, :conditions => ["tire_store_id = ?", self.id], :limit => 50)
  end

  def appointments_with_range(query_date, num_days)
    Appointment.all_store_appointments_with_range(self.id, query_date, num_days)
  end

  def appointments
    @appointments ||= get_appointments
  end

  def get_appointments
    Appointment.store_appointments_with_range(self.id, Date.today, 30)
  end

  ##################################################################################
  # store offerings
  def has_wifi
    return other_property_boolean(:has_wifi)
  end

  def has_wifi=(val)
    self.send(:other_property=, :has_wifi, val)
  end

  def has_coffee
    return other_property_boolean(:has_coffee)
  end

  def has_coffee=(val)
    self.send(:other_property=, :has_coffee, val)
  end

  def has_air
    return other_property_boolean(:has_air)
  end

  def has_air=(val)
    self.send(:other_property=, :has_air, val)
  end

  def has_overnight
    return other_property_boolean(:has_overnight)
  end

  def has_overnight=(val)
    self.send(:other_property=, :has_overnight, val)
  end

  def has_shuttle
    return other_property_boolean(:has_shuttle)
  end

  def has_shuttle=(val)
    self.send(:other_property=, :has_shuttle, val)
  end

  def has_six_month
    return other_property_boolean(:has_six_month)
  end

  def has_six_month=(val)
    self.send(:other_property=, :has_six_month, val)
  end

  def has_twelve_month
    return other_property_boolean(:has_twelve_month)
  end

  def has_twelve_month=(val)
    self.send(:other_property=, :has_twelve_month, val)
  end

  def has_ase_cert
    return other_property_boolean(:has_ase_cert)
  end

  def has_ase_cert=(val)
    self.send(:other_property=, :has_ase_cert, val)
  end

  ##################################################################################
  # store services  
  def has_svc_air_conditioning
    return other_property_boolean(:has_svc_air_conditioning)
  end

  def has_svc_air_conditioning=(val)
    self.send(:other_property=, :has_svc_air_conditioning, val)
  end

  def has_svc_batteries
    return other_property_boolean(:has_svc_batteries)
  end

  def has_svc_batteries=(val)
    self.send(:other_property=, :has_svc_batteries, val)
  end

  def has_svc_belts_hoses
    return other_property_boolean(:has_svc_belts_hoses)
  end

  def has_svc_belts_hoses=(val)
    self.send(:other_property=, :has_svc_belts_hoses, val)
  end

  def has_svc_brake_systems
    return other_property_boolean(:has_svc_brake_systems)
  end

  def has_svc_brake_systems=(val)
    self.send(:other_property=, :has_svc_brake_systems, val)
  end

  def has_svc_electrical_systems
    return other_property_boolean(:has_svc_electrical_systems)
  end

  def has_svc_electrical_systems=(val)
    self.send(:other_property=, :has_svc_electrical_systems, val)
  end

  def has_svc_engine_diag
    return other_property_boolean(:has_svc_engine_diag)
  end

  def has_svc_engine_diag=(val)
    self.send(:other_property=, :has_svc_engine_diag, val)
  end

  def has_svc_headlamps
    return other_property_boolean(:has_svc_headlamps)
  end

  def has_svc_headlamps=(val)
    self.send(:other_property=, :has_svc_headlamps, val)
  end

  def has_svc_heating_cooling
    return other_property_boolean(:has_svc_heating_cooling)
  end

  def has_svc_heating_cooling=(val)
    self.send(:other_property=, :has_svc_heating_cooling, val)
  end

  def has_svc_mufflers
    return other_property_boolean(:has_svc_mufflers)
  end

  def has_svc_mufflers=(val)
    self.send(:other_property=, :has_svc_mufflers, val)
  end

  def has_svc_oil_lube
    return other_property_boolean(:has_svc_oil_lube)
  end

  def has_svc_oil_lube=(val)
    self.send(:other_property=, :has_svc_oil_lube, val)
  end

  def has_svc_maintenance
    return other_property_boolean(:has_svc_maintenance)
  end

  def has_svc_maintenance=(val)
    self.send(:other_property=, :has_svc_maintenance, val)
  end

  def has_svc_packages
    return other_property_boolean(:has_svc_packages)
  end

  def has_svc_packages=(val)
    self.send(:other_property=, :has_svc_packages, val)
  end

  def has_svc_shocks
    return other_property_boolean(:has_svc_shocks)
  end

  def has_svc_shocks=(val)
    self.send(:other_property=, :has_svc_shocks, val)
  end

  def has_svc_starting_systems
    return other_property_boolean(:has_svc_starting_systems)
  end

  def has_svc_starting_systems=(val)
    self.send(:other_property=, :has_svc_starting_systems, val)
  end

  def has_svc_steering_suspension
    return other_property_boolean(:has_svc_steering_suspension)
  end

  def has_svc_steering_suspension=(val)
    self.send(:other_property=, :has_svc_steering_suspension, val)
  end

  def has_svc_timing_belts
    return other_property_boolean(:has_svc_timing_belts)
  end

  def has_svc_timing_belts=(val)
    self.send(:other_property=, :has_svc_timing_belts, val)
  end

  def has_svc_tire_install
    return other_property_boolean(:has_svc_tire_install)
  end

  def has_svc_tire_install=(val)
    self.send(:other_property=, :has_svc_tire_install, val)
  end

  def has_svc_tire_pressure
    return other_property_boolean(:has_svc_tire_pressure)
  end

  def has_svc_tire_pressure=(val)
    self.send(:other_property=, :has_svc_tire_pressure, val)
  end

  def has_svc_systems
    return other_property_boolean(:has_svc_systems)
  end

  def has_svc_systems=(val)
    self.send(:other_property=, :has_svc_systems, val)
  end

  def has_svc_tire_repair
    return other_property_boolean(:has_svc_tire_repair)
  end

  def has_svc_tire_repair=(val)
    self.send(:other_property=, :has_svc_tire_repair, val)
  end

  def has_svc_tire_rotation
    return other_property_boolean(:has_svc_tire_rotation)
  end

  def has_svc_tire_rotation=(val)
    self.send(:other_property=, :has_svc_tire_rotation, val)
  end

  def has_svc_tune_ups
    return other_property_boolean(:has_svc_tune_ups)
  end

  def has_svc_tune_ups=(val)
    self.send(:other_property=, :has_svc_tune_ups, val)
  end

  def has_svc_wheel_alignment
    return other_property_boolean(:has_svc_wheel_alignment)
  end

  def has_svc_wheel_alignment=(val)
    self.send(:other_property=, :has_svc_wheel_alignment, val)
  end

  def has_svc_wheel_balancing
    return other_property_boolean(:has_svc_wheel_balancing)
  end

  def has_svc_wheel_balancing=(val)
    self.send(:other_property=, :has_svc_wheel_balancing, val)
  end

  def has_svc_wipers
    return other_property_boolean(:has_svc_wipers)
  end

  def has_svc_wipers=(val)
    self.send(:other_property=, :has_svc_wipers, val)
  end

  ##################################################################################  

  def min_appt_leadtime_hrs
    return [(other_property(:min_appt_leadtime_hrs) || DEFAULT_APPT_LEAD_TIME_HRS).to_i, DEFAULT_APPT_LEAD_TIME_HRS].max
  end

  def min_appt_leadtime_hrs=(val)
    self.send(:other_property=, :min_appt_leadtime_hrs, val)
  end

  ##################################################################################  

  def other_property_boolean(sym)
    if other_property(sym).blank?
      if Offering.is_valid_store_offering_property(sym)
        return Offering.get_default_store_offering_value(sym)
      elsif Offering.is_valid_service_offering_property(sym)
        return Offering.get_default_service_offering_value(sym)
      else
        return false
      end
    else
      return other_property(sym).to_s.to_bool
    end
  end

  def other_property(sym)
    self.other_properties["#{sym}"]
  end

  def other_property=(sym, val)
    if val.blank?
      self.destroy_key(:other_properties, sym)
    else
      if val != self.other_properties["#{sym}"]
        self.other_properties["#{sym}"] = val
      end
    end
  end

  def distributor_import_id
    if self.has_attribute?(:other_properties)
      return self.other_properties["distributor_import_id"]
    else
      return nil 
    end
  end

  def distributor_import_id=(val)
    if self.has_attribute?(:other_properties)
      if val.blank?
        self.destroy_key(:other_properties, :distributor_import_id)
      else
        self.other_properties["distributor_import_id"] = val 
      end
    end
  end

  def distributor_import
    id = self.distributor_import_id
    if id 
      return DistributorImport.find_by_id(id)
    else
      return nil 
    end
  end

  def short_description
    if self.has_attribute?(:other_properties)
      return self.other_properties["short_description"]
    else
      "No description available"
    end
  end

  def short_description=(val)
    if self.has_attribute?(:other_properties)
      if val.blank?
        self.destroy_key(:other_properties, :short_description)
      else
        self.other_properties["short_description"] = val 
      end
    end
  end

  def short_description_excerpt(max_length)
    if !self.short_description.blank?
      self.short_description[0..max_length].gsub(/\s\w+\s*\z/,'...')
    else
      ""
    end
  rescue
    self.short_description[0..max_length]
  end

  def other_nearby_google_place_stores
    return TireStore.near([self.latitude, self.longitude]).where("private_seller = FALSE AND EXIST(google_properties, 'google_place_id')=TRUE AND google_properties ->'google_place_id' <> 'cannot_find' AND id <> #{self.id}")
  end

  def my_warehouse(distributor)
    if distributor.is_a?(String)
      distributor = Distributor.find_by_name(distributor)
    elsif !distributor.is_a?(Distributor)
      raise "I don't know how to handle a distributor with class #{distributor.class.name}"
    end

    if distributor.nil?
      return nil
    else
      warehouse_xref = TireStoreWarehouse.find_by_distributor_id_and_tire_store_id(distributor.id, self.id)
      if warehouse_xref.nil?
        return nil 
      else
        return Warehouse.find_by_id(warehouse_xref.warehouse_id)
      end
    end
  end

  def upgrade_to_premium(price=$th_monthly_sub_cost)
    if !can_do_ecomm?
      raise "You must register with Stripe before you can become a premium member."
      return
    end

    monthly_cost = price.to_i.to_money
    if has_premium_access?
      raise "Store already has premium access"
      return
    elsif monthly_cost <= 0
      raise "Invalid monthly cost - $#{monthly_cost.to_s}"
      return
    else
      self.premium_access = true 
      self.premium_price = monthly_cost

      if false 
        # Create a Customer
        customer = Stripe::Customer.create(
          :source => token,
          :plan => "Premium",
          :email => self.billing_email
        )
      end
      self.save
    end
  end

  def has_premium_access?
    self.financial_info['premium_access'].to_s.to_bool
  end

  def premium_access=(val)
    if val.blank?
      self.destroy_key(:financial_info, :premium_access)
    else
      self.financial_info['premium_access'] = val.to_s.to_bool
    end
  end

  def premium_price=(val)
    if val.blank?
      self.destroy_key(:financial_info, :premium_price)
    else
      self.financial_info['premium_price'] = val.to_money
    end
  end

  def premium_price
    if self.financial_info['premium_price'].blank?
      return 0.to_money
    else
      self.financial_info['premium_price'].to_money
    end
  end

  def facebook_link
    if !self.has_premium_access
      return nil 
    else
      return self.financial_info['facebook_link']
    end
  end

  def facebook_link=(val)
    if !self.has_premium_access
      raise "This feature is only available for stores on the Premium Plan."
    else
      if /(?:(?:http|https):\/\/)?(?:www.)?facebook.com\/\S+/.match(val)
        self.financial_info['facebook_link'] = val
      else
        raise "Invalid Facebook URL - #{val}"
      end
    end
  end

  def twitter_link
    if !self.has_premium_access
      return nil 
    else
      return self.financial_info['twitter_link']
    end
  end

  def twitter_link=(val)
    if !self.has_premium_access
      raise "This feature is only available for stores on the Premium Plan."
    else
      if /(?:(?:http|https):\/\/)?(?:www.)?twitter.com\/\S+/.match(val)
        self.financial_info['twitter_link'] = val
      else
        raise "Invalid Twitter URL - #{val}"
      end
    end
  end

  def external_website
    if !self.has_premium_access
      return nil 
    else
      return self.financial_info['external_website']
    end
  end

  def external_website=(val)
    if !self.has_premium_access
      raise "This feature is only available for stores on the Premium Plan."
    else
      if val =~ URI::regexp
        self.financial_info['external_website'] = val
      else
        raise "Invalid external website URL - #{val}"
      end
    end
  end


  #private
    def real_address
      "#{self.address1} #{self.address2}, #{self.city}, #{self.state} #{self.zipcode}"
    end

    def heroku_domain_exists(dom)
      result = false

      begin
        if Rails.configuration.heroku_app
          l = heroku.get_domains(Rails.configuration.heroku_app)
          l.body.each do |dom|
            if dom["domain"].casecmp(treadhunter_domain(dom)) == 0 #they're equal
              result = true
            end
          end
        end
      rescue
        result = false
      end

      result
    end

    def ajax_url
      params = instance_variables.grep(/_filter$/).map{|m| "#{m}=#{instance_variable_get(m)}" unless instance_variable_get(m).nil?}.compact.join().gsub(/\@/, "&")
      "/tire_stores/#{self.id}?ajax=true#{params}"
    end

    def filter_link(key, value)
      if self.respond_to?(key)
        "#{ajax_url}&#{key}=#{value}"
      elsif self.respond_to?("#{key}_filter")
        "#{ajax_url}&#{key}_filter=#{value}"
      end
    end

    # conditions
    def tire_store_id_conditions
      ["tire_store_id = ?", self.id]
    end

    def tiresize_conditions
      ["tire_listings.tire_size_id = ?", tire_size_id] unless tire_size_id.blank?
    end

    def tiremodel_id_conditions
      ["tire_listings.tire_model_id = ?", tire_model_id] unless tire_model_id.blank?
    end

    def tiremodel_name_conditions
      ["tire_models.name = ?", tire_model_name] unless tire_model_name.blank?
    end

    def conditions
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

    # filters
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
      #["tire_categories.id = ?", tire_category_id_filter] unless tire_category_id_filter.blank?
      ["tire_models.tire_category_id = ?", tire_category_id_filter] unless tire_category_id_filter.blank?
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

    def set_status(new_status)
      self.status = new_status
      update_column(:status, new_status)

      # since there are potentially so many listings per store, we're going to issue
      # a database query instead of iterating each one
      self.tire_listings.update_all(:status => new_status)
    end
end
