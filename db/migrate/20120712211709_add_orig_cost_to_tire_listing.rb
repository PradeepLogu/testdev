class AddOrigCostToTireListing < ActiveRecord::Migration
  def change
    add_column :tire_listings, :orig_cost, :float
    add_column :tire_listings, :remaining_tread, :string
    add_column :tire_listings, :original_tread, :string
    add_column :tire_listings, :crosspost_craigslist, :boolean
  end
end
