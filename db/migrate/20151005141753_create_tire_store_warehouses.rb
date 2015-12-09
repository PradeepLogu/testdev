class CreateTireStoreWarehouses < ActiveRecord::Migration
  def change
    create_table :tire_store_warehouses do |t|
      t.integer :tire_store_id
      t.integer :distributor_id
      t.integer :warehouse_id

      t.timestamps
    end

	add_index :tire_store_warehouses, [:tire_store_id, :distributor_id], :unique => true
  end
end
