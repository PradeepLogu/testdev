class CreateWarehouseTiers < ActiveRecord::Migration
  def change
    create_table :warehouse_tiers do |t|
      t.integer :warehouse_id
      t.string :tier_name
      t.float :cost_pct_from_base

      t.timestamps
    end

    add_index :warehouse_tiers, [:warehouse_id, :tier_name], :unique => true
  end
end
