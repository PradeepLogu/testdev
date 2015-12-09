class CreateTireStores < ActiveRecord::Migration
  def change
    create_table :tire_stores do |t|
      t.string :name
      t.string :address1
      t.string :address2
      t.string :city
      t.string :state
      t.string :zipcode
      t.string :phone
      t.integer :account_id
      t.float :latitude

      t.timestamps
    end
  end
end
