class AddTireManufacturerToTireSearch < ActiveRecord::Migration
  def change
    add_column :tire_searches, :tire_manufacturer_id, :integer
  end
end
