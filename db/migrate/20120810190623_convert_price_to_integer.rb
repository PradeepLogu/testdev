class ConvertPriceToInteger < ActiveRecord::Migration
  def change
  	change_column :tire_listings, :price, :integer, :null => false
  	change_column :tire_listings, :orig_cost, :integer
  end
end
