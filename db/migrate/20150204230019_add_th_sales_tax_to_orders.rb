class AddThSalesTaxToOrders < ActiveRecord::Migration
  def change
	add_column :orders, :th_sales_tax_collected, :integer, :null => false, :default => 0
  end
end
