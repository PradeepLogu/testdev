class CreateBrandings < ActiveRecord::Migration
  def change
    create_table :brandings do |t|
      t.integer :tire_store_id
      t.datetime :expiration_date
      t.text :listing_html
      t.text :store_html

      t.timestamps
    end
  end
end
