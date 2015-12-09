class AddBrandsCarriedToTireStore < ActiveRecord::Migration
  def change
  	add_column :tire_stores, :brands_carried, :hstore
  end
end
