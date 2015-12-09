class AddPriceAndQuantityToReservations < ActiveRecord::Migration
  def change
    add_column :reservations, :quantity, :integer
    add_column :reservations, :price, :integer
    add_column :reservations, :tire_manufacturer_id, :integer
    add_column :reservations, :tire_model_id, :integer
    add_column :reservations, :tire_size_id, :integer
  end
end
