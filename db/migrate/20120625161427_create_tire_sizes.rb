class CreateTireSizes < ActiveRecord::Migration
  def change
    create_table :tire_sizes do |t|
      t.string :sizestr
      t.integer :diameter
      t.integer :ratio
      t.decimal :wheeldiameter

      t.timestamps
    end
  end
end
