class AddQtyToTireListing < ActiveRecord::Migration
  def change
    add_column :tire_listings, :quantity, :integer
    remove_column :tire_listings, :TireListing
  end
end
