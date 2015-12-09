class AddIsNewToTireListings < ActiveRecord::Migration
  def change
    add_column :tire_listings, :is_new, :boolean, :default => false
  end
end
