class CreateTireModels < ActiveRecord::Migration
  def change
    create_table :tire_models do |t|
      t.integer :tire_manufacturer_id
      t.integer :tire_size_id
      t.integer :load_index
      t.string :speed_rating
      t.float :rim_width
      t.float :tread_depth
      t.string :utqg_temp
      t.integer :utqg_treadwear
      t.string :utqg_traction
      t.string :sidewall

      t.timestamps
    end
  end
end
