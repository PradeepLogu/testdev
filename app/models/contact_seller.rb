class ContactSeller
  include ActiveModel::Validations

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

  validates_presence_of :content, :tire_store_id

  validate :no_profanity, message: "You have included a banned word in your message."

  validates :email, presence:   true,
                    format:     { with: VALID_EMAIL_REGEX, message: "Invalid email format" }
  # to deal with form, you must have an id attribute
  attr_accessor :id, :email, :sender_name, :content, :remote_ip, :tire_store_id, :phone

  def tire_store
    return TireStore.find(self.tire_store_id)
  end

  def initialize(attributes = {})
    attributes.each do |key, value|
      self.send("#{key}=", value)
    end
    @attributes = attributes
  end

  def contact_path_present?
    return !(@email.blank? && @phone.blank?)
  end

  def no_profanity
    if ProfanityFilter::Base.profane?(content)
      errors.add("Message", " contains a banned word.")
    end
  end

  def read_attribute_for_validation(key)
    @attributes[key]
  end

  def to_key
  end

  def persisted?
    false
  end

  def save
    puts "IP is " + self.remote_ip if self.remote_ip
    if self.valid?
      if self.email != "suzypublic@gmail.com"
        ContactsellerMailer.delay.contact_notification(self)
        Device.delay.notify_seller_contact_email(self)
      end
      return true
    else
      puts "**** CONTACT SELLER INVALID ***"
    end
    return false
  end
end