class CreatePromotions < ActiveRecord::Migration
  def change
    create_table :promotions do |t|
      t.integer :promotion_type
      t.integer :tire_manufacturer_id
      t.hstore :tire_model_infos
      t.integer :account_id
      t.hstore :tire_store_ids
      t.date :start_date
      t.date :end_date
      t.text :description
      t.integer :promo_type

      t.timestamps
    end

    add_attachment :promotions, :promo_attachment
    add_attachment :promotions, :promo_image

    execute "CREATE INDEX promotions_tire_model_infos ON promotions USING GIN(tire_model_infos)"
    execute "CREATE INDEX promotions_tire_store_ids ON promotions USING GIN(tire_store_ids)"
  end
end
