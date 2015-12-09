class Notification < ActiveRecord::Base
	include ActionView::Helpers::TextHelper

  attr_accessible :user_id, :account_id, :admin_only, :super_user_only
  attr_accessible :expiration_date, :remaining_views, :message, :title 
  attr_accessible :sticky, :visible_time, :image

  scope "user_notifications", lambda { |user_id| where("user_id = ? and expiration_date >= ? and remaining_views > 0", user_id.to_s, Time.now) }
  scope "user_notifications_since", lambda { |user_id, since| where("user_id = ? and expiration_date >= ? and remaining_views > 0 and created_at >= ?", user_id.to_s, Time.now, since) }
  
  scope "public_account_notifications", lambda { |account_id| where("account_id = ? and admin_only <> true and expiration_date >= ? and remaining_views > 0", 
  								account_id.to_s, Time.now) }
  scope "public_account_notifications_since", lambda { |account_id, since| where("account_id = ? and admin_only <> true and expiration_date >= ? and remaining_views > 0 and created_at >= ?", 
                  account_id.to_s, Time.now, since) }

  scope "admin_account_notifications", lambda { |account_id| where("account_id = ? and admin_only = true and expiration_date >= ? and remaining_views > 0", 
  								account_id.to_s, Time.now) }
  scope "admin_account_notifications_since", lambda { |account_id, since| where("account_id = ? and admin_only = true and expiration_date >= ? and remaining_views > 0 and created_at >= ?", 
                  account_id.to_s, Time.now, since) }

  scope "super_user_notifications", lambda { where("super_user_only = true and expiration_date >= ? and remaining_views > 0", Time.now) }
  scope "super_user_notifications_since", lambda { |since| where("super_user_only = true and expiration_date >= ? and remaining_views > 0 and created_at >= ?", Time.now, since) }

  def formatted_message
  	if self.remaining_views != 99
  		"#{self.message}<br/>#{pluralize(self.remaining_views, 'view')} remaining"
  	else
  		"#{self.message}"
  	end
  end

  def viewed
  	self.decrement!(:remaining_views) unless self.remaining_views == 99
  end

  def set_sticky(p_visible_time)
  	if p_visible_time > 0
  		self.sticky = false
  		self.visible_time = p_visible_time
  	else
  		self.sticky = true
  		self.visible_time = p_visible_time
  	end
  end

  def self.create_user_notification(user_id, message, title, visible_time, expiration_date, remaining_views, image)
  	n = Notification.new(:user_id => user_id, :message => message, :title => title, 
  							:expiration_date => expiration_date, :remaining_views => remaining_views,
  							:admin_only => false, :super_user_only => false, :image => image)
  	n.set_sticky(visible_time)
  	n.save
  end

  def self.create_pending_appointment_confirmations(tire_store_id)
    @tire_store = TireStore.find(tire_store_id)
    msg = "<a href='/appointments/confirm?tire_store_id=#{@tire_store.id}'>You have pending appointments for #{@tire_store.name} (#{@tire_store.id}) - click to view</a>"
    title = "Pending Appointments"
    n = Notification.find(:first, :conditions => ["account_id = ? and message = ? and title = ? and remaining_views > 0 and expiration_date >= ?", @tire_store.account_id, msg, title, Date.today])
    if n.nil?
      puts "Creating notification..."
      Notification.create_public_account_notification(@tire_store.account_id, msg, title, 10000, Time.now + 3.days, 5, "notice")
    else
      puts "Notification exists already..."
    end
  end

  def self.create_error_message(tire_store_id, message)
    @tire_store = TireStore.find(tire_store_id)
    title = "Error"
    n = Notification.find(:first, :conditions => ["account_id = ? and message = ? and title = ? and remaining_views > 0 and expiration_date >= ?", @tire_store.account_id, message, title, Date.today])
    if n.nil?
      Notification.create_public_account_notification(@tire_store.account_id, message, title, 10000, Time.now + 3.days, 5, "error")
    end
  end

  def self.create_public_account_notification(account_id, message, title, visible_time, expiration_date, remaining_views, image)
  	n = Notification.new(:account_id => account_id, :message => message, :title => title, 
  							:expiration_date => expiration_date, :remaining_views => remaining_views,
  							:admin_only => false, :super_user_only => false, :image => image)
  	n.set_sticky(visible_time)
  	n.save
  end

  def self.create_admin_account_notification(account_id, message, title, visible_time, expiration_date, remaining_views, image)
  	n = Notification.new(:account_id => account_id, :message => message, :title => title, 
  							:expiration_date => expiration_date, :remaining_views => remaining_views,
  							:admin_only => true, :super_user_only => false, :image => image)
  	n.set_sticky(visible_time)
  	n.save
  end

  def self.create_super_user_notification(message, title, visible_time, expiration_date, remaining_views, image)
    n = Notification.find(:first, :conditions => ["super_user_only = true and message = ? and title = ? and remaining_views > 0 and expiration_date >= ?", message, title, Date.today])
    if n.nil?
      n = Notification.new(:message => message, :title => title, 
                  :expiration_date => expiration_date, :remaining_views => remaining_views,
                  :admin_only => false, :super_user_only => true, :image => image)
      n.set_sticky(visible_time)
      n.save
    end
  end
end
