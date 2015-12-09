class CreateAppointments < ActiveRecord::Migration
  def up    
  	create_table :appointments do |t|
      t.integer    :tire_store_id,                :null => false
      t.integer    :tire_listing_id,              :null => true
      t.integer    :reservation_id,               :null => false
      t.integer    :user_id,                      :null => true
      t.string     :buyer_email,                  :null => true
      t.string     :buyer_phone,                  :null => true
      t.string     :buyer_name,                   :null => true
      t.string     :buyer_address,                :null => false
      t.string     :buyer_city,                   :null => false
      t.string     :buyer_state,                  :null => false
      t.string     :buyer_zip,                    :null => false
      t.integer    :preferred_contact_path,       :null => false
      t.hstore     :services,                     :null => true
      t.text       :notes,                        :null => true
      t.boolean    :confirmed_flag,               :null => false
      t.boolean    :rejected_flag,                :null => false
      t.date       :request_date_primary,         :null => false
      t.string     :request_hour_primary,         :null => false
      t.date       :request_date_secondary,       :null => false
      t.string     :request_hour_secondary,       :null => false
      t.date       :confirm_date,                 :null => false
      t.string     :confirm_hour,                 :null => false
      t.timestamps
    end  
  end

  def down
  	drop_table :appointments
  end
end