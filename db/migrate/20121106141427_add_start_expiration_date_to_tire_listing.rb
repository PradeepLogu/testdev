class AddStartExpirationDateToTireListing < ActiveRecord::Migration
  def change
    add_column :tire_listings, :start_date, :date
    add_column :tire_listings, :expiration_date, :date
  end
end
