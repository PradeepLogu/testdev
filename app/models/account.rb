include ActionView::Helpers::NumberHelper
include ApplicationHelper

class Account < ActiveRecord::Base
  serialize :brands_carried, ActiveRecord::Coders::Hstore
  serialize :financial_info, ActiveRecord::Coders::Hstore  

  after_create :delay_register_with_stripe

  attr_accessible :name, :phone
  composed_of :address, :class_name => "Address"
  attr_accessible :address1, :address2, :city, :state, :zipcode
  attr_accessible :billing_email, :stripe_id
  has_many :tire_stores
  has_many :tire_listings, :through => :tire_stores
  has_many :reservations, :through => :tire_listings
  has_many :contracts
  has_many :users
  has_many :orders, :through => :tire_stores
  before_validation :validate_phone
  before_save :set_default_brands_carried
  validates_length_of :phone, :presence => true, :maximum => 12, :minimum => 10
  attr_accessible :affiliate_id, :affiliate_time, :affiliate_referrer
  attr_accessible :brands_carried

  attr_accessible :current_contract, :tire_listings, :reservations

  validates_presence_of :name, :address1, :city, :state, :zipcode
  
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :billing_email, presence:   true,
                    format:     { with: VALID_EMAIL_REGEX, message: "Invalid email format" }

  before_destroy { |acct| TireStore.destroy_all "account_id = #{acct.id}" }
  before_destroy { |acct| Contract.destroy_all "account_id = #{acct.id}" }
  before_destroy { |acct| Notification.destroy_all "account_id = #{acct.id}" }
  before_destroy { |acct| Promotion.destroy_all "account_id = #{acct.id}" }

  has_enum_field :status, status_array()

  def admin_user
    u = User.where("account_id = ? and (status <> 2 or status is null) and admin = 1", self.id).first
    if u.nil?
      u = User.where("account_id = ?", self.id).first
    end
    u
  end

  def set_default_brands_carried
    if self.brands_carried.nil? || self.brands_carried.size == 0
      add_tire_manufacturer_id_to_brands_carried(TireManufacturer.find_by_name("Goodyear").id)
      add_tire_manufacturer_id_to_brands_carried(TireManufacturer.find_by_name("BFGoodrich").id)
      add_tire_manufacturer_id_to_brands_carried(TireManufacturer.find_by_name("Michelin").id)
    end
  end

  def manufacturer_names_carried
    result = []
    self.brands_carried.keys.each do |k|
      if self.brands_carried[k] == "tire_manufacturer_id"
        result << TireManufacturer.find(k).name
      end
    end
    result
  end 

  def carries_tire_manufacturer?(tire_manu)
    return false if !tire_manu
    return false if self.brands_carried.nil? || self.brands_carried.size == 0

    return (self.brands_carried[tire_manu.id.to_s] == "tire_manufacturer_id")
  end

  def carries_tire_manufacturer_id?(tire_manu_id)
    return false if !tire_manu_id
    return false if self.brands_carried.nil? || self.brands_carried.size == 0

    return (self.brands_carried[tire_manu_id.to_s] == "tire_manufacturer_id")
  end

  def add_tire_manufacturer_id_to_brands_carried(tire_manufacturer_id)
    self.brands_carried = (brands_carried || {}).merge(tire_manufacturer_id.to_s => "tire_manufacturer_id")
  end

  def remove_tire_manufacturer_id_from_brands_carried(tire_manufacturer_id)
    self.brands_carried = self.brands_carried.except(tire_manufacturer_id.to_s)
  end

  def full_address
    "#{self.address1} #{self.address2}, #{self.city}, #{self.state} #{self.zipcode}"
  end

  def validate_phone
    self.phone = self.phone.gsub(/\D/, '') unless self.phone.nil? # remove non-numeric chars
  end

  def formatted_phone
    number_to_phone(phone)
  end

  def self.search(params)
    state = ''
    keywords = ''
    state = params["State"] if !params.nil?
    keywords = params["Keywords"] if !params.nil?

    if keywords.to_s == '' and state.to_s != ''
    	find(:all, :conditions => ['state = ?', state])
    elsif keywords.to_s != '' and state.to_s != ''
    	find(:all, :conditions => ['name ~* ? and state = ?', keywords, state]) 
    elsif keywords.to_s != '' and state.to_s == ''
      find(:all, :conditions => ['name ~* ?', keywords]) 
    else
      find(:all) if keywords.to_s == '' and state.to_s == ''
    end
  end

  def searches
    @searches ||= get_searches
  end

  def get_searches
    result = []
    if false
      self.tire_stores.each do |t|
        result.concat(t.tire_searches)
      end
    else
      arSearches = []
      self.tire_stores.each do |t|
        arSearches << TireSearch.near([t.latitude, t.longitude], 50).where("created_at >= '" + (Time.now - 7.days).to_s + "'").map(&:id)
      end
      result = TireSearch.select("sizestr, tire_size_id, count(tire_size_id)").where(:id => arSearches).group("sizestr, tire_size_id").joins("inner join tire_sizes on tire_sizes.id = tire_size_id").order("count(tire_size_id) DESC")
    end
    result
  end

  def top_tire_listings
    @top_tire_listings ||= get_top_tire_listings
  end

  def tire_listings
    @tire_listings ||= get_tire_listings
  end

  def get_tire_listings
    result = []
    self.tire_stores.each do |t|
      result.concat(t.tire_listings)
    end
    result
  end

  def get_top_tire_listings
    result = []
    self.tire_stores.each do |t|
      result.concat(TireListing.find(:all, :conditions => ["tire_store_id = ?", t.id], :limit => 50))
    end
    result
  end

  def reservations
    @reservations ||= get_reservations
  end

  def get_reservations
    result = []
    self.tire_stores.each do |t|
      result.concat(t.reservations)
    end
    result
  end

  def affiliate
    @affiliate ||= Affiliate.find_by_id(self.affiliate_id)
  end

  # registers as recipient - someone who can receive money
  def register_with_stripe_as_recipient(tire_store = nil)
    if !self.validate_stripe_id
      begin
        if self.stripe_id.blank?
          if tire_store.nil?
            @tire_stores = self.tire_stores
          else
            @tire_stores = [tire_store]
          end

          @recipient = Stripe::Recipient.create(
            :name => self.name,
            :type => "corporation",
            :tax_id => "000000000",
            ##### :bank_account => "000123456789",
            :country => "US",
            :routing_number => "110000000",
            :account_number => "000123456789",
            :email => self.billing_email,
            :metadata => {"account_id" => "#{self.id}"}
          )
          if @recipient
            puts "Setting stripe id to #{@recipient.id}"
            self.update_attribute(:stripe_id, @recipient.id)
          else
            puts "No stripe id - could not register as recipient"
          end          
        end
      end
    end
  end

  def register_with_stripe
    # obtain a customer id with Stripe...
    if !self.validate_stripe_id
      begin
        if !self.stripe_id || self.stripe_id.length == 0
          if !self.affiliate.nil? && self.affiliate.affiliate_tag.downcase == "sands"
            @customer = Stripe::Customer.create(
              :account_balance => 0,
              :email => self.billing_email,
              :description => self.id.to_s + " - " + self.name,
              :coupon => "SandS"
            )
          elsif !self.affiliate.nil? && self.affiliate.affiliate_tag.downcase == "promo"
            @customer = Stripe::Customer.create(
              :account_balance => 0,
              :email => self.billing_email,
              :description => self.id.to_s + " - " + self.name,
              :coupon => "40off"
            )
          else
            @customer = Stripe::Customer.create(
              :account_balance => 0,
              :email => self.billing_email,
              :description => self.id.to_s + " - " + self.name
            )
          end 

          if @customer
            self.update_attribute(:stripe_id, @customer.id)
          end
        end
      ####rescue Exception => e
        # I want this to fail so it will retry when on delayed job
      end
    end
  end

  def delay_register_with_stripe
    # this registers the account as a Customer, which means they can be billed monthly
    # for service as opposed to being eComm.  The individual stores will add their
    # banking information to become eComm customers.
    self.delay.register_with_stripe
  end

  def stripe_customer_record
    @stripe_customer_record ||= get_stripe_customer_record
  end

  def delete_from_stripe
    cu = get_stripe_customer_record
    if cu
      cu.delete
    end
  end

  def get_stripe_customer_record
    result = nil

    if self.stripe_id && self.stripe_id.length > 0
      begin
        if self.stripe_id.start_with?("rp")
          result = Stripe::Recipient.retrieve(self.stripe_id)
        else
          result = Stripe::Customer.retrieve(self.stripe_id)
        end
      rescue Exception => e 
        result = nil
      end
    end

    return result
  end

  def stripe_invoices
    @stripe_invoices ||= get_stripe_invoices
  end

  def get_stripe_invoices
    if stripe_customer_record
      return Stripe::Invoice.all(:customer => stripe_customer_record.id,
                                  :count => 25)
    end
  end

  def validate_stripe_id
    if self.stripe_id && self.stripe_id.length > 0
      begin
        @customer = self.stripe_customer_record
        if @customer.nil?
          self.update_attribute(:stripe_id, "")
          false
        #elsif @customer.deleted
        #  self.update_attribute(:stripe_id, "")
        #  false
        else
          true
        end
      rescue Stripe::InvalidRequestError => e 
        # bad customer number, erase what we have
        puts "Stripe Error: #{e.to_s}"
        self.update_attribute(:stripe_id, "")
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

  def go_to_cc_collection_page
    # why would we need to go to the credit card page?
    # first, if we have "collect_cc_upfront" global flag set, and we don't have one on file
    # then we need to.  second, if we are still in our free trial and within 15
    # days of expiration, then we need to.  third, if our free trial has expired, we
    # need to.

    have_cc_on_file = !need_to_get_credit_card

    if !have_cc_on_file
      if collect_cc_upfront && !have_cc_on_file
        return true
      elsif current_contract && current_contract.is_free_trial_plan? &&
            current_contract.EXPIRESSOON
        return true
      elsif current_contract && !current_contract.is_free_trial_plan?
        return true
      else
        return false
      end
    else
      false
    end
  end

  def create_platinum_contract
    puts "**** CREATING PLATINUM"
    if (current_contract.nil? && free_trial_days == 0 && free_trial_months == 0) ||
        (!current_contract.nil? && current_contract.is_free_trial_plan?)
      puts "*** Platinum A"
      contract = Contract.new(:account_id => self.id)
      contract.set_as_platinum_plan()
      contract.start_date = current_contract.expiration_date + 1.second
      contract.expiration_date = contract.start_date + free_trial_expiration
      contract.save

      puts "#{contract.attributes.inspect}"
      contract
    elsif current_contract.nil?
      # do we have an expired free trial?
      # note: unclear here whether we should start now or end of previous contract.
      # for now we'll start now.
      puts "*** Platinum B"
      contract = Contract.new(:account_id => self.id)
      contract.set_as_platinum_plan()
      contract.start_date = Time.now
      contract.expiration_date = contract.start_date + free_trial_expiration
      contract.save

      contract
    else
      puts "*** Platinum FAIL"
    end
  end

  def create_gold_contract
    puts "**** CREATING GOLD"
    if (current_contract.nil? && free_trial_days == 0 && free_trial_months == 0) ||
        (!current_contract.nil? && current_contract.is_free_trial_plan?)
      puts "*** Gold A"
      contract = Contract.new(:account_id => self.id)
      contract.set_as_gold_plan()
      contract.start_date = current_contract.expiration_date + 1.second
      contract.expiration_date = contract.start_date + free_trial_expiration
      contract.save

      puts "#{contract.attributes.inspect}"
      contract
    elsif current_contract.nil?
      # do we have an expired free trial?
      # note: unclear here whether we should start now or end of previous contract.
      # for now we'll start now.
      puts "*** Gold B"
      contract = Contract.new(:account_id => self.id)
      contract.set_as_gold_plan()
      contract.start_date = Time.now
      contract.expiration_date = contract.start_date + free_trial_expiration
      contract.save

      contract
    else
      puts "*** Platinum FAIL"
    end
  end

  def create_silver_contract
    if (current_contract.nil? && free_trial_days == 0 && free_trial_months == 0) ||
        (!current_contract.nil? && current_contract.is_free_trial_plan?)
      puts "**** CREATING SILVER B"
      contract = Contract.new(:account_id => self.id)
      contract.set_as_silver_plan()
      contract.start_date = current_contract.expiration_date + 1.second
      contract.expiration_date = contract.start_date + free_trial_expiration
      contract.save

      puts "#{contract.attributes.inspect}"
      contract
    elsif current_contract.nil?
      puts "**** CREATING SILVER B"
      # do we have an expired free trial?
      # note: unclear here whether we should start now or end of previous contract.
      # for now we'll start now.
      contract = Contract.new(:account_id => self.id)
      contract.set_as_silver_plan()
      contract.start_date = Time.now
      contract.expiration_date = contract.start_date + free_trial_expiration
      contract.save

      puts "#{contract.attributes.inspect}"
      contract
    else
      puts "*** Silver FAIL"
    end
  end

  def create_free_trial_contract(effective_date = Time.now, trial_length = free_trial_expiration)
    # a free trial contract can only be created if there is no contract in place
    if current_contract.nil? && trial_length > 0
      contract = Contract.new(:account_id => self.id)
      contract.set_as_free_trial_plan()
      contract.start_date = effective_date
      contract.expiration_date = effective_date + trial_length
      contract.save

      contract
    end
  end

  def create_special_billing_contract(amount, start_date, end_date)
    contract = Contract.new(:account_id => self.id)
    contract.set_as_special_pricing_plan
    contract.contract_amount = amount
    contract.start_date = start_date
    contract.expiration_date = end_date
    contract.bill_cc = true
    contract.save

    contract
  end

  def need_to_get_credit_card?
    return need_to_get_credit_card
  end

  def need_to_get_credit_card
    if self.stripe_id && self.stripe_id.length > 0
      puts "Checking to see if we have a card..."
      begin
        @customer = stripe_customer_record
        if @customer
          if @customer.delinquent
            return true # failed charge
          else
            puts "We have #{@customer.cards.count} cards on file."
            return @customer.cards.count == 0
          end
        else
          # we had trouble, let's validate the stripe customer id and give up.
          # we'll get em next time they log in.
          puts "Could not get customer for #{self.stripe_id}"
          validate_stripe_id()
          false
        end
      rescue Exception => e
        # we had an error getting the stripe customer information.
        # if we can't get stuff from stripe, no point in trying to continue to do so.
        puts "Exception: #{e.to_s}"
        false
      end
    else
      # we don't have a customer ID with stripe yet.  Let's try to get one.
      # we'll say we don't need to get a CC and get 'em next time they log in.
      self.delay_register_with_stripe
      false
    end
  end

  def is_private_seller?
    return (tire_stores.nil? || tire_stores.count == 0 || tire_stores.first.private_seller)
  end

  def current_contract
  	@current_contract ||= get_current_contract
  end

  def most_recent_contract
    @most_recent_contract ||= get_most_recent_contract
  end

  def get_current_contract
  	Contract.where('account_id = ? and start_date <= ? and expiration_date >= ?',
  							self.id, Time.now, Time.now).last
  end

  def get_most_recent_contract
    if current_contract.nil?
      Contract.where('account_id = ? and start_date <= ? and expiration_date >= ?',
                  self.id, Time.now, Time.now).order("expiration_date DESC").first
    else
      current_contract
    end
  end

  def has_active_contract?
  	!$check_contract || !current_contract.nil?
  end

  def can_post_listings?
  	!$check_contract || (!current_contract.nil? && current_contract.can_post_listings)
  end

  def can_have_filter_portal?
    if tire_stores && tire_stores.first && tire_stores.first.private_seller?
      false 
    else
      !$check_contract || (!current_contract.nil? && current_contract.can_have_filter_portal)
    end
  end

  def can_have_search_portal?
    if tire_stores && tire_stores.first && tire_stores.first.private_seller?
      false 
    else
      !$check_contract || (!current_contract.nil? && current_contract.can_have_search_portal)
    end
  end

  def can_use_branding?
    if tire_stores && tire_stores.first && tire_stores.first.private_seller?
      false 
    else
      !$check_contract || (!current_contract.nil? && current_contract.can_use_branding)
    end
  end

  def can_use_logo?
    if tire_stores && tire_stores.first && tire_stores.first.private_seller?
      false 
    else
      !$check_contract || (!current_contract.nil? && current_contract.can_use_logo)
    end
  end

  def can_use_mobile?
    if tire_stores && tire_stores.first && tire_stores.first.private_seller?
      false 
    else
      !$check_contract || (!current_contract.nil? && current_contract.can_use_mobile)
    end
  end

  def set_status(new_status)
    self.status = new_status
    update_column(:status, new_status)

    # since there are potentially so many listings per store, we're going to issue
    # a database query instead of iterating each one
    self.tire_stores.each do |store|
      store.set_status(new_status)
    end
  end

  def appointments(query_date, num_days)
    # scope "store_appointments_with_range", lambda { |tire_store_id, query_date, num_days| 
    result = nil
    self.tire_stores.each do |t|
      @appts = t.appointments_with_range(query_date, num_days)
      if result.nil?
        result = @appts
      else
        result.merge(@appts)
      end
    end
    result
  end

  ################################################################
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

  def default_routing_number
    self.financial_info['default_routing_number']
  end

  def default_routing_number=(routing_number)
    if routing_number.blank?
      self.destroy_key(:financial_info, :default_routing_number)
    else
      self.financial_info['default_routing_number'] = routing_number
    end
  end

  def has_taken_survey
    self.financial_info['survey_complete']
  end

  def has_taken_survey=(survey_taken)
    if survey_taken.blank?
      self.destroy_key(:financial_info, :survey_complete)
    else
      self.financial_info['survey_complete'] = survey_taken
    end
  end

  def base64_account_id
    ##Base64.urlsafe_encode64(self.id.to_s)
    Base64.urlsafe_encode64(Base64.encode64(OpenSSL::HMAC.digest('sha256', "+1r3sRu5", self.id.to_s.rjust(20, '0'))))
  end

  def correct_base64_account_id?(base64_id)
    if self.base64_account_id == base64_id
      return true 
    else
      return false
    end
  end

  def survey_url(request_host_with_port)
    "#{request_host_with_port}/pages/account_survey?secret=#{self.base64_account_id}&account_id=#{self.id}"
  end

  def has_a_store_with_ecomm?
    bFoundOne = false
    if allow_ecomm()
      self.tire_stores.each do |t|
        if t.can_do_ecomm?
          bFoundOne = true
          break
        end
      end
    end
    return bFoundOne
  end
end
