include ApplicationHelper

class AddStatusToTireListingsAndTireStoresAndAccounts < ActiveRecord::Migration
  def change
  	remove_column :tire_listings, :status

    add_column :accounts, :status, :integer, :null => false, :default => status_array[:active]
    add_column :tire_stores, :status, :integer, :null => false, :default => status_array[:active]
    add_column :tire_listings, :status, :integer, :null => false, :default => status_array[:active]

    add_index  :accounts, :status, :name => "accounts_status_index", :unique => false
    add_index  :tire_stores, :status, :name => "tire_stores_status_index", :unique => false
    add_index  :tire_listings, :status, :name => "tire_listings_status_index", :unique => false
    add_index  :tire_listings, [:tire_store_id, :status], :name => "tire_listings_tire_store_id_status_index", :unique => false

	add_index :tire_listings, [:latitude, :longitude, :status], :name => "tire_listings_geocode_status", :unique => false
	add_index :tire_stores, [:latitude, :longitude, :status], :name => "tire_stores_geocode_status", :unique => false
  end
end
