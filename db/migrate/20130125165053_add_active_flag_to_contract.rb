class AddActiveFlagToContract < ActiveRecord::Migration
  def change
    add_column :contracts, :active, :boolean, :default => false
  end
end
