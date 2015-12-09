class AddDomainToTireStores < ActiveRecord::Migration
  def change
    add_column :tire_stores, :domain, :string
  end
end
