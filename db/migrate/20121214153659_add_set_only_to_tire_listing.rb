class AddSetOnlyToTireListing < ActiveRecord::Migration
  def change
    add_column :tire_listings, :sell_as_set_only, :boolean, :default => true
  end
end
