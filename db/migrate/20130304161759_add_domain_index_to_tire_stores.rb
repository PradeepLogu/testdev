class AddDomainIndexToTireStores < ActiveRecord::Migration
  def change
  	add_index(:tire_stores, :domain)
  end
end
