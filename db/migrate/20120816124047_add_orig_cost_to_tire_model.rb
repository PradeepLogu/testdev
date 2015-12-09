class AddOrigCostToTireModel < ActiveRecord::Migration
  def change
    add_column :tire_models, :orig_cost, :integer
  end
end
