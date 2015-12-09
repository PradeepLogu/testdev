class AddTireManufacturersToDistributors < ActiveRecord::Migration
  def change
  	add_column :distributors, :tire_manufacturers, :hstore
  end
end
