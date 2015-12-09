class CreateTireModelPricings < ActiveRecord::Migration
  def change
    create_table :tire_model_pricings do |t|
      t.integer :tire_model_id
      t.string :source # eg eBay, CheckAFlip, TCI API, Goodyear, etc.
      t.string :orig_source # eBay, TCI API, Goodyear, etc.
      t.string :source_url
      t.string :price_type # eg retail, wholesale, msrp
      t.float :tire_ea_price
      t.hstore :other_properties

      t.timestamps
    end

    add_index :tire_model_pricings, :tire_model_id
  end
end
