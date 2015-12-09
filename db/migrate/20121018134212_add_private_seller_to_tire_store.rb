class AddPrivateSellerToTireStore < ActiveRecord::Migration
  def change
    add_column :tire_stores, :private_seller, :boolean, :default => false
  end
end
