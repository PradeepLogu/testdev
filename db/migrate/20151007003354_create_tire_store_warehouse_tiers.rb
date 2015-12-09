class CreateTireStoreWarehouseTiers < ActiveRecord::Migration
  def change
    create_table :tire_store_warehouse_tiers do |t|
      t.integer :tire_store_id
      t.integer :warehouse_id
      t.integer :warehouse_tier_id

      t.timestamps
    end
    add_index :tire_store_warehouse_tiers, [:tire_store_id, :warehouse_id], :unique => true, :name => 'store_warehouse_index'
  end
end
