class AddStockNumberToTireListing < ActiveRecord::Migration
  def change
    add_column :tire_listings, :stock_number, :string
  end
end
