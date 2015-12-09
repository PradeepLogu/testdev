class AddBrandsCarriedToAccount < ActiveRecord::Migration
  def change
  	add_column :accounts, :brands_carried, :hstore
  end
end
