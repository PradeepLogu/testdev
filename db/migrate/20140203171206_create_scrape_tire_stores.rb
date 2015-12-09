class CreateScrapeTireStores < ActiveRecord::Migration
  def up
    create_table "scrape_tire_stores" do |t|
      t.string   "name"
      t.integer  "store_id"
      t.string   "additional_info"
      t.string   "address1"
      t.string   "address2"
      t.string   "city"
      t.string   "state"
      t.string   "zipcode"
      t.string   "phone"
      t.integer  "scraper_id"
      t.float    "latitude"
      t.float    "longitude"
      t.datetime "created_at", :null => false
      t.datetime "updated_at", :null => false
    end

    add_index "scrape_tire_stores", ["scraper_id"], :name => "scrape_tire_stores_scraper_id"
    add_index "scrape_tire_stores", ["latitude", "longitude"], :name => "scrape_tire_stores_geocode"
    add_index "scrape_tire_stores", ["scraper_id", "store_id"], :name => "scrape_tire_stores_store_id", :unique => true
  end

  def down
  end
end
