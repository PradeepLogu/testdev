class AddFieldsToTireManufacturer < ActiveRecord::Migration
  def change
  	add_column :tire_manufacturers, :tgp_brand_id, :integer, :default => 0
  end
end
