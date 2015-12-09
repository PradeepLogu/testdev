class CreateWarehouses < ActiveRecord::Migration
  def change
    create_table :warehouses do |t|
      t.integer :distributor_id
      t.string :name
      t.string :address1
      t.string :address2
      t.string :city
      t.string :state
      t.string :zipcode
      t.string :contact_name
      t.string :contact_email
      t.string :contact_phone

      t.timestamps
    end
    add_index :warehouses, [:distributor_id], :unique => false
  end
end
