class AddGooglePropertiesToTireStore < ActiveRecord::Migration
  def change
  	add_column :tire_stores, :google_properties, :hstore
  end
end
