class Warehouse < ActiveRecord::Base
  attr_accessible :address1, :address2, :city, :contact_email, :contact_name, :contact_phone, :distributor_id, :name, :state, :zipcode
end
