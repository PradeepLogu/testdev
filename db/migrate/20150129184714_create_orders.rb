class CreateOrders < ActiveRecord::Migration
  def change
    create_table :orders do |t|
      t.integer :user_id
      t.integer :tire_listing_id
      t.integer :appointment_id
      t.integer :tire_quantity
      t.integer :tire_ea_price
      t.integer :tire_ea_install_price 
      t.integer :th_user_fee
      t.integer :sales_tax_collected
      t.integer :th_processing_fee
      t.string :transfer_id
      t.integer :transfer_amount
      t.hstore :other_properties

      t.timestamps
    end
  end
end
