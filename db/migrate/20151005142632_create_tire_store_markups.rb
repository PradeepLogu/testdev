class CreateTireStoreMarkups < ActiveRecord::Migration
  def change
    create_table :tire_store_markups do |t|
      t.integer :tire_store_id
      t.integer :warehouse_id
      t.integer :tire_manufacturer_id
      t.integer :tire_model_info_id
      t.integer :tire_size_id
      t.integer :tire_model_id
      t.integer :markup_type
      t.float :markup_pct
      t.integer :markup_dollars

      t.timestamps
    end

    add_index :tire_store_markups, [:tire_store_id, :warehouse_id], :unique => false
  end
end
