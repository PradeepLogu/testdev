class PriceQuote
  #include ActiveModel::Validations

  #validates_presence_of :email, :sender_name, :support_type, :content

  # to deal with form, you must have an id attribute
  attr_accessor :description, :tci_part_no, :manu_part_no, :inv_qty, :price, :fet
  attr_accessor :tips_main_price, :tips_disc_price, :vendor
  attr_accessor :format_size, :service_description, :sidewall, :rim_width
  attr_accessor :sec_width, :diameter, :tread_depth, :revs_per_mile
  attr_accessor :max_single, :max_dual, :utqg_treadwear, :utqg_traction
  attr_accessor :utqg_temp, :img_small, :img_large

  def read_attribute_for_validation(key)
    @attributes[key]
  end

  def to_key
  end
end