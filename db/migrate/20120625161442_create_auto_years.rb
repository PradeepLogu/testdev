class CreateAutoYears < ActiveRecord::Migration
  def change
    create_table :auto_years do |t|
      t.string :modelyear
      t.integer :auto_model_id

      t.timestamps
    end
  end
end
