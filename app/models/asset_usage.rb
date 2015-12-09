class AssetUsage < ActiveRecord::Base
  attr_accessible :asset_id, :branding_id, :tire_store_id, :usage_name

  belongs_to :asset
end
