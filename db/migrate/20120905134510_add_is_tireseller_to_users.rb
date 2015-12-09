class AddIsTiresellerToUsers < ActiveRecord::Migration
  def change
    add_column :users, :tireseller, :boolean, :default => false
  end
end
