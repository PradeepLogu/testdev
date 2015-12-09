class AddSourceToTireListing < ActiveRecord::Migration
  def change
  	change_column :tire_listings, :description, :string, :limit => 4096
  	add_column :tire_listings, :source, :string, :limit => 512
  end
end
