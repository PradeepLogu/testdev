class AddStatusesToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :status, :integer, :null => false, :default => order_status_array[:active]
    add_column :orders, :inv_status, :integer, :null => false, :default => inventory_status_array[:unknown]
  end
end
