#require 'rest_client'
#require 'builder'
include ApplicationHelper

class TireListing < ActiveRecord::Base
    is_impressionable
    
  	before_validation :get_coordinates # , :on => :create
    #before_save :check_teaser
  attr_accessible :treadlife, :description, :tire_store_id, :teaser, :latitude, :longitude, :source
  attr_accessible :tire_manufacturer_id, :quantity, :includes_mounting, :warranty_days
  attr_accessible :orig_cost, :remaining_tread, :original_tread, :crosspost_craigslist, :tire_size_id
  attr_accessible :price, :tire_model_id
  attr_accessible :currency, :template, :is_new
  attr_accessible :start_date, :expiration_date, :stock_number, :sell_as_set_only
  attr_accessible :tire_model_info, :redirect_to
  attr_accessible :generic_tire_listing_id, :is_generic
  attr_accessible :willing_to_ship

  attr_accessible :price_source, :warehouse_price_id, :price_updated_at

  before_save :update_model_attributes
  before_save :remove_nil
  #before_save :create_tire_model_info_if_necessary

  before_create :set_expiration_date

  #before_save :set_teaser_and_description

  belongs_to :tire_model
  belongs_to :tire_size
  belongs_to :tire_store
  has_one :account, :through => :tire_store
  has_one :tire_category, :through => :tire_model
  has_many :reservations
  has_many :orders
  belongs_to :tire_manufacturer
  reverse_geocoded_by :latitude, :longitude

  scope :by_price, lambda {|low_price, high_price| where('price >= ? and price <= ?', low_price, high_price)}

  validate :tire_size_must_be_valid, :tire_manufacturer_must_be_valid, :tire_model_must_be_valid

  #validates :treadlife, :presence => true, :numericality => { :only_integer => true, :greater_than => 1,
  #                                                            :less_than => 101 }

  #validates :price, :presence => true, :numericality => { :only_integer => false, :greater_than => 0, :less_than => 10000 }

  validates :quantity, :presence => true, :numericality => { :greater_than => 0, :less_than => 5 }

  #validates_length_of :description, :presence => true, :maximum => 5000, :minimum => 10

  belongs_to :tire_size
    
  composed_of :price,
    :class_name  => "Money",
    :mapping     => [%w(price cents), %w(currency currency_as_string)],
    :constructor => Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
    :converter   => Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }

  attr_accessible :photo1, :photo2, :photo3, :photo4
  has_attached_file :photo1, :styles => { :original => "1024>x768", :medium => "300x300>", :thumb => "50x50>" }
  has_attached_file :photo2, :styles => { :original => "1024>x768", :medium => "300x300>", :thumb => "50x50>" }
  has_attached_file :photo3, :styles => { :original => "1024>x768", :medium => "300x300>", :thumb => "50x50>" }
  has_attached_file :photo4, :styles => { :original => "1024>x768", :medium => "300x300>", :thumb => "50x50>" }

  process_in_background :photo1
  process_in_background :photo2
  process_in_background :photo3
  process_in_background :photo4

  validates_attachment :photo1, :size => { :in => 0..5000.kilobytes }
  validates_attachment :photo2, :size => { :in => 0..5000.kilobytes }
  validates_attachment :photo3, :size => { :in => 0..5000.kilobytes }
  validates_attachment :photo4, :size => { :in => 0..5000.kilobytes }


  has_enum_field :status, status_array()

  def has_already_bought_or_reserved(email_address)
    if Reservation.where(:buyer_email => email_address, :tire_listing_id => self.id).exists? ||
      Appointment.where(:buyer_email => email_address, :tire_listing_id => self.id).exists? ||
      Order.where(:buyer_email => email_address, :tire_listing_id => self.id).exists?
      return true 
    else
      return false
    end
  end

  def needs_to_set_billing(email_address)    
    if Order.where(:buyer_email => email_address, :tire_listing_id => self.id,
                      :appointment_id => nil).exists?
      return true 
    else
      return false
    end
  end

  def needs_to_set_appointment(email_address)
    if Order.where(:buyer_email => email_address, :tire_listing_id => self.id,
                      :appointment_id => nil).exists?
      return true 
    else
      return false
    end
  end

  def search_description_matches(search_filter)
    arTerms = search_filter.downcase.split(" ")
    search_string = search_description().downcase
    result = true 

    arTerms.each do |t|
      if !search_string.include?(t)
        result = false
      end
    end

    return result
  end

  def search_description
    "#{quantity} #{tire_size.sizestr} #{tire_manufacturer.name} #{tire_model.name} #{tire_size.sizestr.gsub(/[^0-9]/, '')}"
  end

  def get_install_price
    if self.includes_mounting
      return 0.00
    else
      return InstallationCost.get_installation_cost(self.tire_store.account_id, self.tire_store_id, self.tire_size.wheeldiameter, (self.tire_model.run_flat_id == 1))
    end
  end

  def get_install_price_parts
    if self.includes_mounting
      return 0.00
    else
      return InstallationCost.get_installation_cost_parts(self.tire_store.account_id, self.tire_store_id, self.tire_size.wheeldiameter, (self.tire_model.run_flat_id == 1))
    end
  end

  def get_install_price_labor
    if self.includes_mounting
      return 0.00
    else
      return InstallationCost.get_installation_cost_labor(self.tire_store.account_id, self.tire_store_id, self.tire_size.wheeldiameter, (self.tire_model.run_flat_id == 1))
    end
  end

  def can_do_ecomm?
    return self.is_new? && self.tire_store.can_do_ecomm? 
  end

  def realtime_quote_distributors
    return tire_model.realtime_quote_distributors
  end

  def eligible_promotions
    result = []

    # first, find all promotions that might possibly fit
    Promotion.eligible_promotions(self, "all").each do |p|
      if p.valid_for_store?(self.tire_store)
        result << p 
      end
    end

    result
  end

  def generic_tire_listing
    return nil if !self.is_generic
    @generic_tire_listing ||= GenericTireListing.find(generic_tire_listing_id)
  end

  def cl_title
    begin
      c = ClTemplate.find_by_account_id_and_tire_store_id(self.tire_store.account_id, self.tire_store_id)
      c.tire_listing = self
      c.formatted_title
    rescue
      ''
    end
  end

  def tire_manufacturer_name
    if self.is_generic
      "Unspecified"
    else
      tire_manufacturer.name
    end
  end

  def tire_model_name
    if self.is_generic
      "Unspecified"
    else
      tire_model.name
    end
  end

  def tire_model_info_id
    if self.is_generic
      "-1"
    else
      self.tire_model_info.id.to_s
    end
  end

  def gendesc_treadlife
    if self.is_generic
      if !generic_tire_listing.treadlife_min.blank? &&
        !generic_tire_listing.treadlife_max.blank? &&
        !generic_tire_listing.remaining_tread_min.blank? &&
        !generic_tire_listing.remaining_tread_max.blank?
        "  These tires have between #{generic_tire_listing.remaining_tread_min}/32s and #{generic_tire_listing.remaining_tread_max}/32s of an inch remaining tread (#{generic_tire_listing.treadlife_min}% to #{generic_tire_listing.treadlife_max}%)."
      elsif !generic_tire_listing.remaining_tread_min.blank? &&
        !generic_tire_listing.remaining_tread_max.blank?
        "  These tires have between #{generic_tire_listing.remaining_tread_min}/32s and #{generic_tire_listing.remaining_tread_max}/32s of an inch remaining tread."
      elsif !generic_tire_listing.treadlife_min.blank? &&
        !generic_tire_listing.treadlife_max.blank?
        "  These tires have a remaining tread life of #{generic_tire_listing.treadlife_min}% to #{generic_tire_listing.treadlife_max}%."
      end
    else
      ""
    end
  end

  def gendesc
    if self.is_generic
      "We have a great selection of used #{self.tire_size.sizestr} tires.#{gendesc_treadlife}  Call or stop in for details."
    else
      ""
    end
  end

  def mount_price
    if self.is_generic
      generic_tire_listing.mounting_price.to_s
    else
      ""
    end
  end
  
  def store_to_param
    tire_store.to_param
  end

  def to_param
    if self.tire_store && self.tire_store.private_seller
      "#{id}-#{self.short_description.parameterize}-#{self.meta_description.parameterize}-#{tire_store.city.parameterize}-#{tire_store.state.parameterize}"
    elsif self.tire_store.nil?
      "#{id}-#{self.short_description.parameterize}-#{self.meta_description.parameterize}"
    else
      "#{id}-#{self.short_description.parameterize}-#{self.meta_description.parameterize}-#{tire_store.name.parameterize}-#{tire_store.city.parameterize}-#{tire_store.state.parameterize}"
    end
  end

  def manufacturer_name
    (self.tire_manufacturer ? self.tire_manufacturer.name : '')
  end

  def model_name
    (self.tire_model ? self.tire_model.name : '')
  end

  def sizestr
    (self.tire_size ? self.tire_size.sizestr : '')
  end

  def wheelsize
    (self.tire_size ? self.tire_size.wheeldiameter.to_i : '')
  end

  def cost_per_tire
    if self.is_new
      self.discounted_price.to_f
    else
      (self.quantity >= 0 ? self.discounted_price.to_f / self.quantity : 0)
    end
  end

  def tire_category_id
    tire_model.nil? ? 0 : (tire_model.tire_category_id.nil? ? 0 : tire_model.tire_category_id)
  end

  def store_visible_name
    self.tire_store.visible_name
  end

  def send_cancellations
  end

  def get_coordinates
  	self.latitude, self.longitude = tire_store.latitude, tire_store.longitude if not tire_store.nil?
  end

  def check_teaser
    teaser = description[0..254] if teaser.nil? or teaser.empty? unless description.nil?
  end

  def tire_size_must_be_valid
    if !TireSize.exists?(self.tire_size_id)
      self.errors.add(:base, "You must select a valid tire size #{self.tire_size_id}.")
    end
  end

  def set_teaser_and_description
    if self.description.nil? || self.description.empty?
      self.description = default_description
    end

    if self.teaser.nil? || self.teaser.empty?
      self.teaser = default_teaser
    end
  end

  def quantity_required_for_reservation?
    (self.is_new || (self.quantity > 1 && !self.sell_as_set_only))
  end

  def breakable_set?
    !self.is_new && self.quantity > 1 && !self.sell_as_set_only
  end

  def compress_photo_array
    # this is a ROYAL PITA.  The problem is that accessing
    # each individual attachment is not easy...so I can get the
    # filename attribute to see if the file exists or not

    arTemp = []
    if !self.photo1_file_name.blank? #.photo1 #.exists?
      puts "Adding photo1 to array"
      arTemp << self.photo1
    end
    if !self.photo2_file_name.blank? #.photo2 #.exists?
      puts "Adding photo2 to array"
      arTemp << self.photo2
    end
    if !self.photo3_file_name.blank? #.photo3 #.exists?
      puts "Adding photo3 to array"
      arTemp << self.photo3
    end
    if !self.photo4_file_name.blank? #.photo4 #.exists?
      puts "Adding photo4 to array"
      arTemp << self.photo4
    end

    if arTemp[0] #&& arTemp[0].exists?
      self.photo1 = arTemp[0]
    else
      self.photo1 = nil
    end
    if arTemp[1] #&& arTemp[1].exists?
      self.photo2 = arTemp[1] 
    else
      self.photo2 = nil
    end
    if arTemp[2] #&& arTemp[2].exists?
      self.photo3 = arTemp[2] 
    else
      self.photo3 = nil
    end
    if arTemp[3] #&& arTemp[3].exists?
      self.photo4 = arTemp[3] 
    else
      self.photo4 = nil
    end

    backtrace_log if backtrace_logging_enabled
    self.save
  end

  def computed_savings
    if self.is_new?
      return 0
    end
    if self.tire_model.nil? || self.tire_model.orig_cost == 0 || 
      self.quantity == 0 || self.treadlife == 0
      0
    else
      tot_orig_cost = self.quantity * self.tire_model.orig_cost.to_f
      tot_expected_cost = (self.treadlife.to_f / 100.0) * tot_orig_cost
      if tot_expected_cost < 1
        0
      else
        (((tot_expected_cost - self.price.to_f) * 100.0) / tot_expected_cost).round
      end
    end
  end

  def default_description
    template.create_description(self)
  end

  def default_teaser
    template.create_teaser(self)
  end

  def template
    @template ||= get_template
  end

  def get_template
    @template = tire_store.cl_template unless tire_store.nil?
  end

  def tire_model_info
    @tire_model_info ||= get_tire_model_info
  end

  def get_tire_model_info
    if self.tire_model && self.tire_manufacturer_id && self.tire_manufacturer_id > 0
      @tire_model_info = TireModelInfo.find_or_create_by_tire_manufacturer_id_and_tire_model_name(self.tire_manufacturer_id, self.tire_model.name)
    end
  end

  def formatted_price
    price.to_s#.to_f
  end

  def has_special_offer?
    return Promotion.eligible_promotions(self, ['O']).count > 0
  end

  def has_special_offer
    return self.has_special_offer?
  end

  def has_rebate?
    if self.is_new 
      return Promotion.eligible_promotions(self, ['R']).count > 0
    else
      return false
    end
  end

  def has_rebate
    self.has_rebate?
  end

  def has_price_break?
    Promotion.eligible_promotions(self, ['P','S', 'D']).count > 0
  end

  def has_price_break
    self.has_price_break?
  end

  def discounted_price
    start_price = price.to_f
    
    self.eligible_promotions.each do |p|
      start_price = p.apply(start_price)
    end

    start_price.to_money.to_s
  end

  def tire_manufacturer_must_be_valid
    if !self.is_generic && !TireManufacturer.exists?(tire_manufacturer_id)
      self.errors.add(:base, "You must select a valid tire manufacturer")
    end
  end  

  def tire_model_must_be_valid
    if !self.is_generic && !TireModel.exists?(tire_model_id)
      self.errors.add(:base, "You must select a valid tire model")
    end
  end

  def default_craigslist_body_template
    '{#desc} <br />' +
    'Our price is {#price} which includes mounting and balancing. <br />' +
    'Click this link for more information about these tires: <br />' +
    '<a href=' + '"' + 'http://www.treadhunter.com/tire_listings/' + id.to_s +
      '"' + ' /> <br /> <br />' +
    'Please call {#phone} for more information. <br />' +
    'Our address is: <br /><br />' +
    '{#address1} <br />' +
    '{#city}, {#state} {#zip}'
  end

  def default_craigslist_title_template
    "({#qty}) Nice {#size} {#mfr} Used Tires - ${#price} ({#store})"
  end

  def craigslist_body
    m = tokens(default_craigslist_body_template)
    default_craigslist_body_template.gsub(/\{#(.*?)\}/, '%s') % params_array(m)
  end

  def tokens(s)
    # regular expression that pulls out all tokens in format {#token}
    s.scan(/\{#(.*?)\}/)
  end

  def craigslist_title
    m = tokens(default_craigslist_title_template)
    default_craigslist_title_template.gsub(/\{#(.*?)\}/, '%s') % params_array(m)
  end

  def logo_thumbnail
    tire_store.branding.logo.url(:thumb) if tire_store.account.can_use_logo? && !tire_store.branding.nil? && tire_store.branding.logo.exists?
  end

  def photo1_thumbnail
    #photo1.url if photo1.exists? #(:medium)
    if self.photo1_file_name
      s3_folder = (1000000000 + self.id.to_i).to_s
      "http://s3.amazonaws.com/#{Rails.application.config.paperclip_defaults[:s3_credentials][:bucket]}/tire_listings/photo1s/#{s3_folder[1, 3]}/#{s3_folder[4, 3]}/#{s3_folder[7, 3]}/medium/#{self.photo1_file_name}" 
    elsif tire_model_info && tire_model_info.photo1_thumbnail
      tire_model_info.photo1_thumbnail
    end
  end 

  def photo1_small
    #photo1.url if photo1.exists? #(:medium)
    if self.photo1_file_name
      s3_folder = (1000000000 + self.id.to_i).to_s
      "http://s3.amazonaws.com/#{Rails.application.config.paperclip_defaults[:s3_credentials][:bucket]}/tire_listings/photo1s/#{s3_folder[1, 3]}/#{s3_folder[4, 3]}/#{s3_folder[7, 3]}/thumb/#{self.photo1_file_name}" 
    elsif tire_model_info && tire_model_info.photo1_thumbnail
      tire_model_info.photo1_thumbnail
    end
  end 

  def photo2_thumbnail
    #photo2.url if photo2.exists?
    s3_folder = (1000000000 + self.id.to_i).to_s
    "http://s3.amazonaws.com/#{Rails.application.config.paperclip_defaults[:s3_credentials][:bucket]}/tire_listings/photo2s/#{s3_folder[1, 3]}/#{s3_folder[4, 3]}/#{s3_folder[7, 3]}/medium/#{self.photo2_file_name}" if self.photo2_file_name
  end 

  def photo2_small
    #photo2.url if photo2.exists?
    s3_folder = (1000000000 + self.id.to_i).to_s
    "http://s3.amazonaws.com/#{Rails.application.config.paperclip_defaults[:s3_credentials][:bucket]}/tire_listings/photo2s/#{s3_folder[1, 3]}/#{s3_folder[4, 3]}/#{s3_folder[7, 3]}/thumb/#{self.photo2_file_name}" if self.photo2_file_name
  end 

  def photo3_thumbnail
    #photo3.url if photo3.exists?
    s3_folder = (1000000000 + self.id.to_i).to_s
    "http://s3.amazonaws.com/#{Rails.application.config.paperclip_defaults[:s3_credentials][:bucket]}/tire_listings/photo3s/#{s3_folder[1, 3]}/#{s3_folder[4, 3]}/#{s3_folder[7, 3]}/medium/#{self.photo3_file_name}" if self.photo3_file_name
  end 

  def photo3_small
    #photo3.url if photo3.exists?
    s3_folder = (1000000000 + self.id.to_i).to_s
    "http://s3.amazonaws.com/#{Rails.application.config.paperclip_defaults[:s3_credentials][:bucket]}/tire_listings/photo3s/#{s3_folder[1, 3]}/#{s3_folder[4, 3]}/#{s3_folder[7, 3]}/thumb/#{self.photo3_file_name}" if self.photo3_file_name
  end 

  def photo4_thumbnail
    #photo4.url if photo4.exists?
    s3_folder = (1000000000 + self.id.to_i).to_s
    "http://s3.amazonaws.com/#{Rails.application.config.paperclip_defaults[:s3_credentials][:bucket]}/tire_listings/photo4s/#{s3_folder[1, 3]}/#{s3_folder[4, 3]}/#{s3_folder[7, 3]}/medium/#{self.photo4_file_name}" if self.photo4_file_name
  end

  def photo4_small
    #photo4.url if photo4.exists?
    s3_folder = (1000000000 + self.id.to_i).to_s
    "http://s3.amazonaws.com/#{Rails.application.config.paperclip_defaults[:s3_credentials][:bucket]}/tire_listings/photo4s/#{s3_folder[1, 3]}/#{s3_folder[4, 3]}/#{s3_folder[7, 3]}/thumb/#{self.photo4_file_name}" if self.photo4_file_name
  end

  def picture_count
    (photo1.exists? ? 1 : 0) +
    (photo2.exists? ? 1 : 0) +
    (photo3.exists? ? 1 : 0) +
    (photo4.exists? ? 1 : 0)
  end

  def params_array(m)
    ar = Array.new
    m.each do |i|
      case i[0]
        when 'desc'
          ar << description
        when 'price' 
          ar << price
        when 'phone' 
          ar << tire_store.visible_phone
        when 'address1' 
          ar << tire_store.address1
        when 'city' 
          ar << tire_store.city
        when 'state' 
          ar << tire_store.state
        when 'zip' 
          ar << tire_store.zipcode
        when 'size'
          ar << tire_size.sizestr
        when 'mfr'
          ar << tire_manufacturer.name
        when 'qty'
          ar << quantity
        when 'store'
          ar << tire_store.visible_name
        else 
          ar << i[0]
      end
    end

    ar
  end

  def cc_short_description
    (tire_size.nil? ? "" : " " + tire_size.sizestr) +
    (tire_manufacturer.nil? ? "" : " " + tire_manufacturer.name) +
    (tire_model.nil? ? "" : " " + tire_model.name)
  end

  def short_description
    "(#{quantity})" + 
    (tire_size.nil? ? "" : " " + tire_size.sizestr) +
    (tire_manufacturer.nil? ? "" : " " + tire_manufacturer.name) +
    (tire_model.nil? ? "" : " " + tire_model.name)
  end

  def full_order_description(order, appt)
    (order.nil? ? "#{appt.quantity}" : "(#{order.tire_quantity})") +
    (tire_size.nil? ? "" : " " + tire_size.sizestr) +
    (tire_manufacturer.nil? ? "" : " " + tire_manufacturer.name) +
    (tire_model.nil? ? "" : " " + tire_model.name) +
    (self.stock_number.blank? ? "" : " (stock #: #{self.stock_number})")
  end

  def meta_description
    (tire_size.nil? ? "" : " " + tire_size.sizestr.gsub(/R/, '/'))
  end

  def set_expiration_date
    if self.created_at
      ###self.expiration_date = self.created_at + 30.days
      self.expiration_date = '2099-12-31' # for now, doesn't really expire
    else
      ###self.expiration_date = Date.today + 30.days
      self.expiration_date = '2099-12-31' # for now, doesn't really expire
    end
  end

  def renew_listing
    self.expiration_date = Date.today + 30.days
  end

  private

    def create_tire_model_info_if_necessary
      get_tire_model_info()
      #if @tire_model_info
      #  if 
      #end
    end

    def remove_nil
      self.is_new = false if self.is_new == nil
      self.includes_mounting = false if self.includes_mounting == nil
      true
    end

    def update_model_attributes
      if self.is_new?
        self.treadlife = 100
      end
      
      unless tire_model.nil?
        begin
          self.original_tread = tire_model.tread_depth
          tot_real_tread = original_tread - 2

          self.treadlife = ((100 * (self.remaining_tread - 2) / tot_real_tread)).round

          if self.treadlife > 100
            self.treadlife = 100
          elsif self.treadlife < 0
            self.treadlife = 0
          end
        rescue
          # not that important, just ignore
        end

        begin
          if self.tire_model.tire_size_id != self.tire_size_id
            puts "We have a problem - sizes don't match - my size = #{self.tire_size.sizestr}, model = #{self.tire_model.tire_size.sizestr}"
            self.tire_model.tire_size_id = self.tire_model.tire_size_id
          end
        rescue
        end
      end
    end
end