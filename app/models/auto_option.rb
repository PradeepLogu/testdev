class AutoOption < ActiveRecord::Base
  attr_accessible :name, :tire_size_id, :auto_year_id
  has_one :tire_size
  belongs_to :auto_year
  has_one :auto_model, :through => :auto_year
  has_one :auto_manufacturer, :through => :auto_model
end
