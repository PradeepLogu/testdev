class ContactUs
  include ActiveModel::Validations

  validates_presence_of :email, :sender_name, :support_type, :content

  # to deal with form, you must have an id attribute
  attr_accessor :id, :email, :sender_name, :support_type, :content, :remote_ip

  def initialize(attributes = {})
    attributes.each do |key, value|
      self.send("#{key}=", value)
    end
    @attributes = attributes
  end

  def read_attribute_for_validation(key)
    @attributes[key]
  end

  def to_key
  end

  def save
    #puts "IP is " + self.remote_ip if self.remote_ip
    if self.valid?
      #ContactusMailer.support_notification(self).deliver
      ContactusMailer.delay.support_notification(self)
      return true
    else
      puts "**** CONTACT US INVALID ***"
    end
    return false
  end
end