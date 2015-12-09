class AddPasswordToTireStoresDistributors < ActiveRecord::Migration
  def change
    add_column :tire_stores_distributors, :username, :string
    add_column :tire_stores_distributors, :password_digest, :string
  end
end
