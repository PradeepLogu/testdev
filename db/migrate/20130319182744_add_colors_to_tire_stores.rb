class AddColorsToTireStores < ActiveRecord::Migration
  def change
    add_column :tire_stores, :colors, :hstore
  end
end
