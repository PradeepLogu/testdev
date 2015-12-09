class Tire < ActiveRecord::Base
  attr_accessible :performancecategory, :sidewall, :speedrating, :year
  composed_of :tire_manufacturer
  composed_of :tire_size
end
