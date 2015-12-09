class ClTemplate < ActiveRecord::Base
  attr_accessible :account_id, :tire_store_id
  attr_writer :tire_listing

  # these define the main text for a CL posting.  They will have a default
  # value but very well may be overwritten
  attr_accessible :body, :title
  attr_accessible :body_new_listings, :title_new_listings

  # these are going to always be store-specific
  attr_accessible :cl_email, :cl_password
  attr_accessible :cl_posting_page
  attr_accessible :cl_subarea, :cl_specific_location

  # these are generally going to be defaults
  attr_accessible :cl_login_page, :cl_logout_page
  attr_accessible :cl_login_email_fieldname, :cl_login_password_fieldname
  attr_accessible :cl_ad_name, :cl_ad_value
  attr_accessible :cl_category_name, :cl_category_value
  attr_accessible :cl_title_field, :cl_price_field, :cl_specific_location_field

  attr_accessor :default_template

  # this is generally a default too but a bit different - it's a serialized hash
  # used to define actions taken while posting a CL listing.  This is a "text" field.
  serialize :cl_actions

  def as_json(options = { })
    self.cl_email = "" if self.cl_email.nil?
    self.cl_password = "" if self.cl_password.nil?
    self.cl_subarea = "" if self.cl_subarea.nil?
    self.cl_specific_location = "" if self.cl_specific_location.nil?
    self.cl_posting_page = "" if self.cl_posting_page.nil?

    super(:only => [:cl_email, :cl_password, :cl_posting_page, :cl_subarea, :cl_specific_location], 
                  :methods => [:login_page, :logout_page, :login_email_fieldname,
                                :login_password_fieldname, :ad_name, :ad_value,
                                :category_name, :category_value, :title_field, :price_field,
                                :specific_location_field, 
                                :formatted_title, :formatted_body, :new_record])
  end

  def default_template
    if account_id == 0
      self 
    else
      @default_template ||= load_default_template
    end
  end

  def new_record
    (Time.now - self.created_at < 60)
  end

  def load_default_template
    ClTemplate.find_by_account_id_and_tire_store_id(0, 0)
  end

  def cl_body
    if @tire_listing.is_new
      (body_new_listings.presence || default_template.body_new_listings)
    else
      (body.presence || default_template.body)
    end
  end

  def cl_title
    if @tire_listing.is_new
      (title_new_listings.presence || default_template.title_new_listings)
    else
      (title.presence || default_template.title)
    end
  end

  def formatted_body
    create_description(@tire_listing) if @tire_listing
  end

  def formatted_title
    create_teaser(@tire_listing) if @tire_listing
  end

  def login_page
    cl_login_page.presence || default_template.cl_login_page
  end

  def logout_page
    cl_logout_page.presence || default_template.cl_logout_page
  end

  def login_email_fieldname
    cl_login_email_fieldname.presence || default_template.cl_login_email_fieldname
  end

  def login_password_fieldname
    cl_login_password_fieldname.presence || default_template.cl_login_password_fieldname
  end

  def ad_name
    cl_ad_name.presence || default_template.cl_ad_name
  end

  def ad_value
    cl_ad_value.presence || default_template.cl_ad_value
  end

  def category_name
    cl_category_name.presence || default_template.cl_category_name
  end

  def category_value
    cl_category_value.presence || default_template.cl_category_value
  end

  def title_field
    cl_title_field.presence || default_template.cl_title_field
  end

  def price_field
    cl_price_field.presence || default_template.cl_price_field
  end

  def specific_location_field
    cl_specific_location_field.presence || default_template.cl_specific_location_field
  end

  def create_description(tire_listing)
    begin
      puts "**** CL_BODY IS #{cl_body}"
      d = tire_listing.tire_size.diameter.to_s
      r = tire_listing.tire_size.ratio.to_s
      w = tire_listing.tire_size.wheeldiameter.to_i.to_s
      all_sizes = "#{d}/#{r}R#{w}\r\n#{d}/#{r}-#{w}\r\n#{d}/#{r}/#{w}\r\n#{d}-#{r}-#{w}\r\n#{d}.#{r}.#{w}\r\n#{d}/#{r}.#{w}\r\n"
      m = tokens(cl_body)
      b = cl_body.gsub(/\{#(.*?)\}/, '%s') % params_array(m, tire_listing)
      "#{b}\r\n\r\n\r\nSize:\r\n#{all_sizes}"
    rescue Exception => e
      puts "*** ERROR" + e.to_s
      ""
    end
  end

  def create_teaser(tire_listing)
    begin
      m = tokens(cl_title)
      cl_title.gsub(/\{#(.*?)\}/, '%s') % params_array(m, tire_listing)
    rescue
      ""
    end
  end
  
  def tokens(s)
    # regular expression that pulls out all tokens in format {#token}
    s.scan(/\{#(.*?)\}/)
  end

  def params_array_values(m, *param_values)
  	ar = Array.new
  	m.each do |i|
  		ar << (param_values)
  	end
  end

  def params_array(m, tire_listing)
    ar = Array.new
    m.each do |i|
      case i[0]
        when 'price' 
          ar << (tire_listing.price.nil? ? "" : tire_listing.price)
        when 'phone' 
          ar << (tire_listing.tire_store.nil? ? "" : tire_listing.tire_store.visible_phone)
        when 'address1' 
          ar << (tire_listing.tire_store.nil? ? "" : tire_listing.tire_store.address1)
        when 'city' 
          ar << (tire_listing.tire_store.nil? ? "" : tire_listing.tire_store.city)
        when 'state' 
          ar << (tire_listing.tire_store.nil? ? "" : tire_listing.tire_store.state) 
        when 'zip' 
          ar << (tire_listing.tire_store.nil? ? "" : tire_listing.tire_store.zipcode)
        when 'size'
          ar << (tire_listing.tire_size.nil? ? "" : tire_listing.tire_size.sizestr.gsub(/\//, '/').gsub(/R/, '-'))
        when 'mfr'
          ar << (tire_listing.tire_manufacturer.nil? ? "" :  tire_listing.tire_manufacturer.name)
        when 'qty'
          ar << (tire_listing.quantity.nil? ? "" : tire_listing.quantity)
        when 'model'
          ar << (tire_listing.tire_model.nil? ? "" : tire_listing.tire_model.name)
        when 'store'
          ar << (tire_listing.tire_store.nil? ? "" : tire_listing.tire_store.visible_name)
        when 'treaddepth'
          ar << (tire_listing.remaining_tread.nil? ? "" : tire_listing.remaining_tread)
        when 'treadlife'
          ar << (tire_listing.treadlife.nil? ? "" : tire_listing.treadlife)
        when 'inc_mount'
          ar << (tire_listing.includes_mounting.nil? || !tire_listing.includes_mounting ? "" : " Price includes mounting and balancing.")
        when 'warranty'
          ar << (tire_listing.warranty_days.nil? || tire_listing.warranty_days.to_i == 0 ? "" : " #{tire_listing.warranty_days} day warranty included.")
        when 'logo'
          ar << ('<img src="' + tire_listing.tire_store.branding.logo.url + '">' if tire_listing.tire_store.branding && tire_listing.tire_store.branding.logo.exists?)
        else 
          ar << i[0]
      end
    end

    ar
  end
end

