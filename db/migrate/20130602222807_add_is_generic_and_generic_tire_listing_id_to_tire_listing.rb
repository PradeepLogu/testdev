class AddIsGenericAndGenericTireListingIdToTireListing < ActiveRecord::Migration
  def change
    add_column :tire_listings, :is_generic, :boolean, :default => false
    add_column :tire_listings, :generic_tire_listing_id, :integer, :default => -1
  end
end
