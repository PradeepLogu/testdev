class CreateAutoModels < ActiveRecord::Migration
  def change
    create_table :auto_models do |t|
      t.string :name
      t.integer :auto_manufacturer_id

      t.timestamps
    end
  end
end
