class CreateReservations < ActiveRecord::Migration
  def change
    create_table :reservations do |t|
      t.integer :user_id
      t.integer :tire_listing_id
      t.string :buyer_email
      t.string :seller_email
      t.string :name
      t.string :address
      t.string :city
      t.string :state
      t.string :zip
      t.string :phone
      t.datetime :expiration_date

      t.timestamps
    end
  end
end
