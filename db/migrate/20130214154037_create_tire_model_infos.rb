class CreateTireModelInfos < ActiveRecord::Migration
  def change
    create_table :tire_model_infos do |t|
      t.integer :tire_manufacturer_id
      t.string :tire_model_name
      t.string :photo1_url
      t.string :photo2_url
      t.string :photo3_url
      t.string :photo4_url

      t.timestamps
    end
  end
end
