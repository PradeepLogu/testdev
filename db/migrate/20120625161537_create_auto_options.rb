class CreateAutoOptions < ActiveRecord::Migration
  def change
    create_table :auto_options do |t|
      t.string :name
      t.integer :auto_year_id
      t.integer :tire_size_id

      t.timestamps
    end
  end
end
