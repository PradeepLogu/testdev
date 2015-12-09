class CreateDistributorImports < ActiveRecord::Migration
  def change
    create_table :distributor_imports do |t|
    	t.string :uuid, :null => false
    	t.string :distributor_tier, :null => false
    	t.integer :distributor_id, :null => false
    	t.integer :warehouse_id, :null => false
    	t.string :store_name
    	t.string :store_address1
    	t.string :store_address2
    	t.string :store_city
    	t.string :store_state
    	t.string :store_zipcode
    	t.string :store_phone
    	t.string :store_contact_first_name
    	t.string :store_contact_last_name
    	t.string :store_contact_email
    	t.float  :latitude
    	t.float  :longitude
    	t.boolean :clicked
    	t.datetime :clicked_at
    	t.boolean :registered
    	t.datetime :registered_at
    	t.hstore :other_information

    	# after registration
		t.integer :tire_store_id

		t.timestamps
    end
    add_index :distributor_imports, [:uuid], :unique => true
  end
end
