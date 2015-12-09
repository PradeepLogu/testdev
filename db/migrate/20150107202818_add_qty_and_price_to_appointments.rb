class AddQtyAndPriceToAppointments < ActiveRecord::Migration
  def change
    add_column :appointments, :quantity, :integer
    add_column :appointments, :price, :integer
  end
end
