class AddPropertiesToOrders < ActiveRecord::Migration
  def change
	add_column :orders, :stripe_properties, :hstore
  end
end
