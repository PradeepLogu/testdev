class AddPropertiesToBrandings < ActiveRecord::Migration
  def change
    add_column :brandings, :properties, :hstore
  end
end
