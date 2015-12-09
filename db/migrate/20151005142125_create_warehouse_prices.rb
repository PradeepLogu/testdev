class CreateWarehousePrices < ActiveRecord::Migration
  def change
    create_table :warehouse_prices do |t|
      t.integer :warehouse_id
      t.integer :warehouse_tier_id
      t.integer :tire_model_id
      t.integer :base_price_warehouse_price_id
      t.integer :base_price
      t.float :cost_pct_from_base
      t.integer :wholesale_price

      t.timestamps
    end
  end
end
