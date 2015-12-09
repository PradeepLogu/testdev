class AddWillingToShipToTireStores < ActiveRecord::Migration
  def change
  	add_column :tire_stores, :willing_to_ship, :integer, :default => 0
  end
end
