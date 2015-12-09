class AddGooglePropertiesToScrapeTireStore < ActiveRecord::Migration
  def change
  	add_column :scrape_tire_stores, :google_properties, :hstore
  end
end
