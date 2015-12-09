class Registration
  include ActiveRecord::Validations
  
  attr_accessor :user, :account, :tire_store, :store_type, :store_phone
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  
  validate :all_fields_okay
  
  #user
  validates :first_name, presence: true, length: { maximum: 50 }
  validates :last_name, presence: true, length: { maximum: 50 }
  validates :email, presence:   true,
                    format:     { with: VALID_EMAIL_REGEX, message: "Invalid email format" },
                    uniqueness: { case_sensitive: false }
  validates :password, presence: true, length: { minimum: 6 }
  validates :password_confirmation, presence: true
  validates_confirmation_of :password
  
  #tire_store
  validates_presence_of :name, :message => 'You must enter a store name'
  validates_presence_of :address1, :message => 'You must enter an address'
  validates_presence_of :city, :message => 'You must enter a city'
  validates_length_of :phone, :presence => true, :maximum => 12, :minimum => 10
  validates_presence_of :zipcode
  
#  validates_length_of :text_phone, :presence => true, :maximum => 10, :minimum => 10, :if => :send_text
#  validates :domain.downcase, :exclusion=> { :in => %w(www beta) }, :allow_blank => true, :allow_nil => true
#  validates_uniqueness_of :domain, :allow_blank => true, :allow_nil => true
#  validate :valid_domain
  
  def initialize(attributes = {})
    @user = User.new
    @account = Account.new
    @tire_store = TireStore.new
    if !attributes.nil?
      attributes.each do |key, value|
        self.send("#{key}=", value)
      end
    end
    @attributes = attributes
  end
  
  def set_errors
    errors.clear
    
    self.user.errors.each do |e1, e2|
      errors.add(e1, e2)
    end    
    
    self.account.errors.each do |e1, e2|
      errors.add(e1, e2)
    end
    
    self.tire_store.errors.each do |e1, e2|
      errors.add(e1, e2)
    end
  end
  
  def save
    if !@store_type.nil? && @store_type.downcase == "private"
      @tire_store.name = @account.name = @user.name
    end

    User.transaction do
      if @user.save
        if @account.save
          @user.update_attribute(:account_id, @account.id)
    
          @tire_store.account_id = @account.id
          @tire_store.save
        else
          raise ActiveRecord::Rollback
        end
      else
        raise ActiveRecord::Rollback
      end
    end
    
    set_errors
    return self.errors.count == 0
  end
  
  def new_record?
    true
  end
  
  def first_name
    @user.first_name
  end
  
  def first_name=(x)
    @user.first_name = x
  end
  
  def last_name
    @user.last_name
  end
  
  def last_name=(x)
    @user.last_name = x
  end
  
  def email
    @user.email
  end
  
  def email=(x)
    @user.email = x
    @account.billing_email = x
    @tire_store.contact_email = x
  end
  
  def password
    @user.password
  end
  
  def password=(x)
    @user.password = x
  end
  
  def password_confirmation
    @user.password_confirmation
  end
  
  def password_confirmation=(x)
    @user.password_confirmation = x
  end
  
  def all_fields_okay
    return (user.validate)
  end
  
  def phone
    @user.phone
  end
  
  def phone=(x)
    @user.phone = x
    # @tire_store.phone = x
    @account.phone = x
  end

  def store_phone
    @tire_store.phone
  end

  def store_phone=(x)
    @tire_store.phone = x
  end
  
  def name
    @account.name
  end
  
  def name=(x)
    @account.name = x
    @tire_store.name = x
  end
  
  def address1
    @account.address1
  end
  
  def address1=(x)
    @account.address1 = x
    @tire_store.address1 = x
  end
  
  def address2
    @account.address2
  end
  
  def address2=(x)
    @account.address2 = x
    @tire_store.address2 = x
  end
  
  def city
    @account.city
  end
  
  def city=(x)
    @account.city = x
    @tire_store.city = x
  end
  
  def state
    @account.state
  end
  
  def state=(x)
    @account.state = x
    @tire_store.state = x
  end
  
  def zipcode
    @account.zipcode
  end
  
  def zipcode=(x)
    @account.zipcode = x
    @tire_store.zipcode = x
  end
  
  def store_type=(x)
    @store_type = x
    if x.downcase == "private"
      @tire_store.private_seller = true
    else
      @tire_store.private_seller = false
    end
  end
  
  def hide_phone=(x)
    if true
      @tire_store.hide_phone = true
    else
      @tire_store.hide_phone = false
    end
  end
  
  def to_key
  end
end