class AddQuantityToTireSearch < ActiveRecord::Migration
  def change
    add_column :tire_searches, :quantity, :integer, :default => 0
  end
end
