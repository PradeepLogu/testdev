class AddAuthorizedTireManufacturerIDsToTireStore < ActiveRecord::Migration
  def change
    add_column :tire_stores, :authorized_promotion_tire_manufacturer_ids, :hstore
  end
end
