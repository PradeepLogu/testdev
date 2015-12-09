class CreateAutoManufacturers < ActiveRecord::Migration
  def change
    create_table :auto_manufacturers do |t|
      t.string :name

      t.timestamps
    end
  end
end
