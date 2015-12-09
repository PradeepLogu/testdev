class AutoModel < ActiveRecord::Base
  attr_accessible :auto_manufacturer_id, :name
  has_many :auto_years
  belongs_to :auto_manufacturer
  accepts_nested_attributes_for :auto_manufacturer
end
