class AddTireStoreIdIndexToTireListings < ActiveRecord::Migration
  def change
  	add_index :tire_listings, :tire_store_id
  end
end
