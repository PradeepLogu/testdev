class AddQuantityToContracts < ActiveRecord::Migration
  def change
    add_column :contracts, :quantity, :integer, :default => 1
  end
end
