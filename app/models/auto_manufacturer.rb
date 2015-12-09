class AutoManufacturer < ActiveRecord::Base
  attr_accessible :name
  has_many :auto_models
  has_many :auto_years, :through => :auto_models
  has_many :auto_options, :through => :auto_years
end
