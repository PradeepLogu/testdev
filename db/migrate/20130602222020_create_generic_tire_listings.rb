class CreateGenericTireListings < ActiveRecord::Migration
  def change
    create_table :generic_tire_listings do |t|
      t.integer :remaining_tread_min
      t.integer :remaining_tread_max
      t.integer :treadlife_min
      t.integer :treadlife_max
      t.integer :tire_store_id
      t.integer :quantity
      t.boolean :includes_mounting
      t.integer :warranty_days
      t.hstore :tire_sizes
      t.string :currency
      t.integer :price
      t.integer :mounting_price

      t.timestamps
    end
  end
end
