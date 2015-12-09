class AddPromotionIndexToTireStores < ActiveRecord::Migration
  def change
  	  execute "CREATE INDEX promotions_tire_manufacturer_ids ON tire_stores USING GIN(authorized_promotion_tire_manufacturer_ids)"
  end
end
