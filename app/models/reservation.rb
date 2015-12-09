include ActionView::Helpers::NumberHelper

class CancelParty
  BUYER=1
  SELLER=2
  SYSTEM=3
end

class Reservation < ActiveRecord::Base
  #include ActiveModel::Validations
  apply_simple_captcha
  
  attr_accessible :address, :buyer_email, :city, :expiration_date, :name
  attr_accessible :seller_email, :state, :tire_listing_id, :user_id, :zip
  attr_accessible :phone
  attr_accessible :quantity, :price, :tire_manufacturer_id, :tire_model_id, :tire_size_id
  attr_accessor :cancelled_by
  after_create :send_new_reservation_emails
  after_create :send_new_reservation_notifications
  after_destroy :send_cancellation_emails

  has_one :tire_store, :through => :tire_listing

  has_one :tire_manufacturer
  has_one :tire_model
  has_one :tire_size

  belongs_to :tire_listing
  belongs_to :user

  validates :buyer_email, :presence => true, :email => true
  validates_presence_of :name
  validates_uniqueness_of :user_id, :scope => [:tire_listing_id], :unless => Proc.new { user_id <= 0 }, :message => ": You have already reserved this tire."
  validates_uniqueness_of :buyer_email, :scope => [:tire_listing_id], 
                        :message => ": This email has already reserved this tire."
  before_validation :validate_phone
  validates_length_of :phone, :presence => true, :maximum => 12, :minimum => 10

  composed_of :price,
    :class_name  => "Money",
    :mapping     => [%w(price cents), %w(currency currency_as_string)],
    :constructor => Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
    :converter   => Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }

  validate do |reservation|
    if reservation.buyer_email.blank? and reservation.phone.blank?
      reservation.errors.add('Must provide a way to contact you (phone or email)')
    end
  end
  
  def validate_phone
    self.phone = self.phone.gsub(/\D/, '') # remove non-numeric chars
  end

  def formatted_phone
    number_to_phone(phone)
  end

  def formatted_price
    price.to_s#.to_f
  end

  def cancel_reservation(cancelParty)
    cancelled_by = cancelParty
  end

  def mobile_format
    '["' + "#{tire_listing.teaser}" + '", "' + "#{name}" + '", "' + "#{buyer_email}" + '", "' + "#{phone}" + '", "' + "#{tire_listing.tire_size.sizestr}" + '"],'
  end

  def photo1_url
    begin
      "#{tire_listing.photo1_thumbnail}"
    rescue
      ""
    end
  end

  def listing_description
    begin
      "#{tire_listing.quantity} #{tire_listing.tire_size.sizestr} #{tire_listing.tire_manufacturer.name} #{tire_listing.tire_model.name}"
    rescue
      ""
    end
  end

  def listing_price
    begin
      tire_listing.formatted_price.to_s
    rescue
      ""
    end
  end

  def send_new_reservation_notifications
    Device.notify_seller_reservation(self)
  end

  def send_new_reservation_emails
    begin
      ReservationMailer.delay.tire_buyer_reservation(self)
    rescue Exception => e
      puts "*** ERROR SENDING BUYER RESERVATION #{e.to_s}"
    end

    begin
      if self.buyer_email != "suzypublic@gmail.com"
        if tire_listing.tire_store.send_text # seller wants text
          text_msg = ReservationMailer.tire_seller_reservation_text(self)
          ts = TextSender.new()
          ts.send_text(tire_listing.tire_store.text_phone, text_msg.body.to_s)
        else
          ReservationMailer.delay.tire_seller_reservation(self)
        end
      end
    rescue Exception => e
      puts "*** ERROR SENDING SELLER RESERVATION #{e.to_s}"
    end
  end

  def send_cancellation_emails
    case cancelled_by
    when CancelParty::BUYER
      send_cancelled_by_buyer_emails
    when CancelParty::SYSTEM
      send_cancelled_by_system_emails
    else
      send_cancelled_by_seller_emails
    end
  end

  private
    def send_cancelled_by_seller_emails
      ReservationMailer.tire_buyer_cancellation_by_seller(self).deliver
      ReservationMailer.tire_seller_cancellation_by_seller(self).deliver
    end

    def send_cancelled_by_buyer_emails
      ReservationMailer.tire_buyer_cancellation_by_buyer(self).deliver
      ReservationMailer.tire_seller_cancellation_by_buyer(self).deliver
    end

    def send_cancelled_by_system_emails
      ReservationMailer.tire_buyer_cancellation_by_system(self).deliver
      ReservationMailer.tire_seller_cancellation_by_system(self).deliver
    end
end
