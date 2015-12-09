class AutoYear < ActiveRecord::Base
  attr_accessible :auto_model_id, :modelyear
  has_many :auto_options
  belongs_to :auto_model
end
