class AddAccountIdAndTireStoreIdToDevice < ActiveRecord::Migration
  def change
  	add_column :devices, :account_id, :integer
  	add_column :devices, :tire_store_id, :integer
  end
end
