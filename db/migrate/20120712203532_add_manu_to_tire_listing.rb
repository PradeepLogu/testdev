class AddManuToTireListing < ActiveRecord::Migration
  def change
    add_column :tire_listings, :TireListing, :string
    add_column :tire_listings, :tire_manufacturer_id, :integer
    add_column :tire_listings, :includes_mounting, :boolean
    add_column :tire_listings, :warranty_days, :integer
  end
end
