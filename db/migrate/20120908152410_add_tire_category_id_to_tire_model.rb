class AddTireCategoryIdToTireModel < ActiveRecord::Migration
  def change
    add_column :tire_models, :tire_cateogry_id, :integer, :default => 0
  end
end
