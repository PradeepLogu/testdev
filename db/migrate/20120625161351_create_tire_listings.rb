class CreateTireListings < ActiveRecord::Migration
  def change
    create_table :tire_listings do |t|
      t.integer :treadlife
      t.decimal :price
      t.integer :status
      t.string :description
      t.string :teaser
      t.integer :tire_store_id
      t.integer :tire_size_id
      t.float :latitude
      t.float :longitude

      t.timestamps
    end
  end
end
