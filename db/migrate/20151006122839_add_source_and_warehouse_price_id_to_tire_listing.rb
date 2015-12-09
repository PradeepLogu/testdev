class AddSourceAndWarehousePriceIdToTireListing < ActiveRecord::Migration
  def change
    add_column :tire_listings, :price_source, :integer
    add_column :tire_listings, :warehouse_price_id, :integer
    add_column :tire_listings, :price_updated_at, :datetime
  end
end
