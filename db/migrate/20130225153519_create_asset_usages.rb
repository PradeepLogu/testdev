class CreateAssetUsages < ActiveRecord::Migration
  def change
    create_table :asset_usages do |t|
      t.integer :tire_store_id
      t.integer :branding_id
      t.integer :asset_id
      t.string :usage_name

      t.timestamps
    end
  end
end
