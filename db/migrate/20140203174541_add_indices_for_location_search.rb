class AddIndicesForLocationSearch < ActiveRecord::Migration
  def up
    add_index "tire_stores", ["latitude", "longitude"], :name => "tire_stores_geocode"
    add_index "tire_listings", ["latitude", "longitude"], :name => "tire_listings_geocode"
  end

  def down
  end
end
