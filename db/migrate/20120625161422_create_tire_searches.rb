class CreateTireSearches < ActiveRecord::Migration
  def change
    create_table :tire_searches do |t|
      t.integer :auto_manufacturer_id
      t.integer :auto_model_id
      t.integer :auto_year_id
      t.integer :auto_options_id
      t.integer :tire_size_id
      t.integer :user_id

      t.timestamps
    end
  end
end
