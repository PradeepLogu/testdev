class AddOtherPropertiesToTireStores < ActiveRecord::Migration
  def change
  	add_column :tire_stores, :other_properties, :hstore
  end
end
