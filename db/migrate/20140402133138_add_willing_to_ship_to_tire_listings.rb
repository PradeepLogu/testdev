class AddWillingToShipToTireListings < ActiveRecord::Migration
  def change
  	add_column :tire_listings, :willing_to_ship, :integer, :default => 0
  end
end
