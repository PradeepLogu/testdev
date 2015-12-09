class AddFieldsToOrder < ActiveRecord::Migration
  def change
  	add_column :orders, :buyer_email, :string, :null => false
  	add_column :orders, :buyer_name, :string, :null => false
  	add_column :orders, :buyer_address1, :string, :null => false
  	add_column :orders, :buyer_address2, :string
  	add_column :orders, :buyer_city, :string, :null => false
  	add_column :orders, :buyer_state, :string, :null => false
  	add_column :orders, :buyer_zip, :string, :null => false

  	add_index :orders, [:buyer_email], :unique => false
  	add_index :orders, [:tire_listing_id], :unique => false
  end
end
