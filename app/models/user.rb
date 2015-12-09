
class User < ActiveRecord::Base
  include SessionsHelper
  
  attr_accessible :email, :first_name, :last_name, :status, :password, :password_confirmation
  attr_accessible :phone, :tireseller, :admin
  attr_accessible :password_reset_token, :password_reset_sent_at, :mobile_token
  attr_accessible :tire_store_id
  attr_accessible :affiliate_id, :affiliate_time, :affiliate_referrer

  attr_accessible :zipcode

  #has_phone_number :phone, :validate_on => :update, :validation_message => 'Invalid phone number format.'
  belongs_to :account
  has_many :tire_stores, :through => :account
  has_many :reservations
  belongs_to :tire_store
  has_secure_password

  before_save { |user| user.email = email.downcase }
  before_save :create_remember_token

  validates :first_name, presence: true, length: { maximum: 50 }

  validates_inclusion_of :tireseller, :in => [true, false]

  validates :last_name, presence: true, length: { maximum: 50 }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence:   true,
                    format:     { with: VALID_EMAIL_REGEX, message: "Invalid email format" },
                    uniqueness: { case_sensitive: false }

  validates :password, 
                    presence: true, 
                    length: { minimum: 6 },
                    :if       => :password_changed?
  validates :password_confirmation, 
                    presence: true,
                    :if       => :password_changed?

  before_validation :validate_phone
  validates_length_of :phone, :presence => true, :maximum => 12, :minimum => 10

  serialize :other_properties, ActiveRecord::Coders::Hstore

  def self.other_properties_list
    [
      :email_yearly_tire_reminders,
      :email_local_tire_deals,
      :email_local_shop_oil_changes,
      :email_local_shop_other_services
    ]
  end

  def password_changed?
    password_digest_changed?
  end  

  def initialize(attributes = {})
    result = super(attributes.except(*User.other_properties_list))
    set_other_properties(attributes)
    return result
  end

  def update_attributes(attributes = {})
    result = super(attributes.except(*User.other_properties_list))
    set_other_properties(attributes)
    return result
  end

  def set_other_properties(attributes)
    attributes.each do |att, val|
      if User.other_properties_list.include?(att.to_sym)
        puts "Setting #{att} to #{val}"
        self.send("#{att}=", val)
      else
        puts "other_properties_list does not include #{att}"
      end
    end    
  end  
  
  def validate_phone
    self.phone = self.phone.gsub(/\D/, '') unless self.phone.nil? # remove non-numeric chars
  end

  def saved_searches
    TireSearch.where('user_id = ? and saved_search_frequency <> ?', self.id, '')
  end

  def formatted_phone
    number_to_phone(phone)
  end

  def secure_digest(*args)
    Digest::SHA1.hexdigest(args.flatten.join('--'))
  end
  
  def is_admin?
    (admin == 1)
  end

  def public_mobile_token
    token_encode(self.mobile_token)
  end

  def public_token
    token_encode(self.remember_token)
  end

  def name
    first_name + ' ' + last_name
  end

  def is_super_user?
    (status == 2)
  end

  def is_tireseller?
    (tireseller == true)
  end

  def is_tirebuyer?
    !is_tireseller?
  end

  def send_password_reset
    generate_token(:password_reset_token)
    self.update_attribute(:password_reset_token, self.password_reset_token)
    self.update_attribute(:password_reset_sent_at, Time.zone.now)
    #self.password_reset_sent_at = Time.zone.now
    #save!
    UserMailer.password_reset(self).deliver
  end

  def set_mobile_token
    self.mobile_token = secure_digest("#{self.email}#{self.password_digest}TheF0nz#{self.created_at.to_s}")
    self.update_attribute(:mobile_token, self.mobile_token)
  end

  def generate_token(column)
    begin
      self[column] = SecureRandom.urlsafe_base64
    end while User.exists?(column => self[column])
  end


  ###################################################################################################
  # Boolean properties
  ###################################################################################################

  def email_yearly_tire_reminders
    return other_property_boolean(:email_yearly_tire_reminders)
  end

  def email_yearly_tire_reminders=(val)
    self.send(:other_property=, :email_yearly_tire_reminders, val)
  end

  def email_local_tire_deals
    return other_property_boolean(:email_local_tire_deals)
  end

  def email_local_tire_deals=(val)
    self.send(:other_property=, :email_local_tire_deals, val)
  end  

  def email_local_shop_oil_changes
    return other_property_boolean(:email_local_shop_oil_changes)
  end

  def email_local_shop_oil_changes=(val)
    self.send(:other_property=, :email_local_shop_oil_changes, val)
  end   

  def email_local_shop_other_services
    return other_property_boolean(:email_local_shop_other_services)
  end

  def email_local_shop_other_services=(val)
    self.send(:other_property=, :email_local_shop_other_services, val)
  end  

  private
    def create_remember_token
      self.remember_token = SecureRandom.urlsafe_base64
    end

    def other_property_boolean(sym)
      return other_property(sym).to_s.to_bool
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
end
