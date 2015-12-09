class AddRememberTokenToUsers < ActiveRecord::Migration
  def change
  	add_column :users, :remember_token, :string
  	add_column :users, :admin, :integer, :default => 0
  	add_column :users, :account_id, :integer, :default => 0
    add_index  :users, :remember_token
  end
end
