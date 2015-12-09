class ChangeTreadToFloat < ActiveRecord::Migration
  def change
  	remove_column :tire_listings, :remaining_tread
  	remove_column :tire_listings, :original_tread

  	add_column :tire_listings, :remaining_tread, :float 
  	add_column :tire_listings, :original_tread, :float
  end
end
