class CreateTireManufacturers < ActiveRecord::Migration
  def change
    create_table :tire_manufacturers do |t|
      t.string :name

      t.timestamps
    end
  end
end
