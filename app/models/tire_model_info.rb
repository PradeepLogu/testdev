class TireModelInfo < ActiveRecord::Base
  attr_accessible :tire_manufacturer_id, :tire_model_name
  attr_accessible :photo1_url, :photo2_url, :photo3_url, :photo4_url
  attr_accessible :description
  before_save :get_pictures #, :email_if_no_photo

  belongs_to :tire_manufacturer

  attr_accessible :tgp_model_id

  has_many :tire_models

  serialize :tgp_features, ActiveRecord::Coders::Hstore
  serialize :tgp_benefits, ActiveRecord::Coders::Hstore
  serialize :tgp_other_attributes, ActiveRecord::Coders::Hstore

  attr_accessible :stock_photo1, :stock_photo2, :stock_photo3, :stock_photo4
  has_attached_file :stock_photo1, :styles => { :original => "1024>x768", :medium => "300x300>", :thumb => "50x50>" }
  has_attached_file :stock_photo2, :styles => { :original => "1024>x768", :medium => "300x300>", :thumb => "50x50>" }
  has_attached_file :stock_photo3, :styles => { :original => "1024>x768", :medium => "300x300>", :thumb => "50x50>" }
  has_attached_file :stock_photo4, :styles => { :original => "1024>x768", :medium => "300x300>", :thumb => "50x50>" }

  def tire_listings
	tm = TireModel.find_all_by_tire_manufacturer_id_and_name(self.tire_manufacturer_id, self.tire_model_name)
	TireListing.find(:all, :conditions => ['tire_model_id in (?)', tm.collect(&:id)])
  end

  def listings_count
	tm = TireModel.find_all_by_tire_manufacturer_id_and_name(self.tire_manufacturer_id, self.tire_model_name)
	TireListing.count(:conditions => ['tire_model_id in (?)', tm.collect(&:id)])
  end

  def listings_count_no_photos
	tm = TireModel.find_all_by_tire_manufacturer_id_and_name(self.tire_manufacturer_id, self.tire_model_name)
	TireListing.count(:conditions => ['tire_model_id in (?) AND photo1_file_name is ?', tm.collect(&:id), nil])
  end

  def photo1_thumbnail
    #photo1.url if photo1.exists? #(:medium)
    s3_folder = (1000000000 + self.id.to_i).to_s
    "http://s3.amazonaws.com/#{Rails.application.config.paperclip_defaults[:s3_credentials][:bucket]}/tire_model_infos/stock_photo1s/#{s3_folder[1, 3]}/#{s3_folder[4, 3]}/#{s3_folder[7, 3]}/medium/#{self.stock_photo1_file_name}" if self.stock_photo1_file_name
  end

  def photo2_thumbnail
    #photo1.url if photo1.exists? #(:medium)
    s3_folder = (1000000000 + self.id.to_i).to_s
    "http://s3.amazonaws.com/#{Rails.application.config.paperclip_defaults[:s3_credentials][:bucket]}/tire_model_infos/stock_photo1s/#{s3_folder[1, 3]}/#{s3_folder[4, 3]}/#{s3_folder[7, 3]}/medium/#{self.stock_photo2_file_name}" if self.stock_photo2_file_name
  end

  def photo3_thumbnail
    #photo1.url if photo1.exists? #(:medium)
    s3_folder = (1000000000 + self.id.to_i).to_s
    "http://s3.amazonaws.com/#{Rails.application.config.paperclip_defaults[:s3_credentials][:bucket]}/tire_model_infos/stock_photo1s/#{s3_folder[1, 3]}/#{s3_folder[4, 3]}/#{s3_folder[7, 3]}/medium/#{self.stock_photo3_file_name}" if self.stock_photo3_file_name
  end

  def photo4_thumbnail
    #photo1.url if photo1.exists? #(:medium)
    s3_folder = (1000000000 + self.id.to_i).to_s
    "http://s3.amazonaws.com/#{Rails.application.config.paperclip_defaults[:s3_credentials][:bucket]}/tire_model_infos/stock_photo1s/#{s3_folder[1, 3]}/#{s3_folder[4, 3]}/#{s3_folder[7, 3]}/medium/#{self.stock_photo4_file_name}" if self.stock_photo4_file_name
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

  def get_tgp_features
  	self.tgp_features.sort_by{|k, v| k.to_i}.map(&:second) 
  end

  def set_tgp_features(feature_no, feature_str)
  	key = "#{feature_no.to_s.rjust(3, '0')}"
    if feature_str.blank?
      self.destroy_key(:tgp_features, :key)
    else
      self.tgp_features[key] = feature_str
    end
  end  

  def get_tgp_benefits
  	self.tgp_benefits.sort_by{|k, v| k.to_i}.map(&:second) 
  end

  def set_tgp_benefits(benefit_no, benefit_str)
  	key = "#{benefit_no.to_s.rjust(3, '0')}"
    if benefit_str.blank?
      self.destroy_key(:tgp_benefits, :key)
    else
      self.tgp_benefits[key] = benefit_str
    end
  end  

  def get_tgp_other_attributes
  	self.tgp_other_attributes.sort_by{|k, v| k.to_i}.map(&:second) 
  end

  def set_tgp_other_attributes(attribute_no, attribute_str)
  	key = "#{attribute_no.to_s.rjust(3, '0')}"
    if attribute_str.blank?
      self.destroy_key(:tgp_other_attributes, :key)
    else
      self.tgp_other_attributes[key] = attribute_str
    end
  end  

  protected
  	def get_pictures
  		begin
	  		if self.photo1_url_changed?
	  			if !self.photo1_url || self.photo1_url.size == 0
	  				self.stock_photo1.clear
	  			else
	                self.stock_photo1 = open(self.photo1_url)
	  			end
	  		end

	  		if self.photo2_url_changed?
	  			if !self.photo2_url || self.photo2_url.size == 0
	  				self.stock_photo2.clear
	  			else
	                self.stock_photo2 = open(self.photo2_url)
	  			end
	  		end

	  		if self.photo3_url_changed?
	  			if !self.photo3_url || self.photo3_url.size == 0
	  				self.stock_photo3.clear
	  			else
	                self.stock_photo3 = open(self.photo3_url)
	  			end
	  		end

	  		if self.photo4_url_changed?
	  			if !self.photo4_url || self.photo4_url.size == 0
	  				self.stock_photo4.clear
	  			else
	                self.stock_photo4 = open(self.photo4_url)
	  			end
	  		end
	  	rescue Exception => e 
	  		puts e.to_s
	  	end
  	end

  	def email_if_no_photo
  		if !self.stock_photo1.exists? && !self.stock_photo2.exists? && 
  			!self.stock_photo3.exists? && !self.stock_photo4.exists?
  			begin
	  			c = ContactUs.new()
	  			c.email = "treadhunter.mailer@gmail.com"
	  			c.sender_name = "Missing Photo"
	  			c.support_type = "MissingPhoto"
	  			c.content = "We need photos entered for #{self.tire_manufacturer.name} (#{self.tire_manufacturer_id}) #{self.tire_model_name}"
	  			c.save()
	  		rescue Exception => e
	  			puts e.to_s
	  		end
  		end
  	end
end
