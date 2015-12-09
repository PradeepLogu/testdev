class AddTireStoreIdUpdatedAtIndexToTireListings < ActiveRecord::Migration
  def change
  	add_index :tire_listings, [:tire_store_id, :updated_at], :unique => false
  end
end
