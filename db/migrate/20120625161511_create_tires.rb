class CreateTires < ActiveRecord::Migration
  def change
    create_table :tires do |t|
      t.integer :year
      t.string :sidewall
      t.string :speedrating
      t.string :performancecategory
      t.integer :tire_manufacturer_id
      t.integer :tire_size_id

      t.timestamps
    end
  end
end
