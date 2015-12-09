class AddTireStoreIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :tire_store_id, :integer
  end
end
