class AddFieldsToTireModels < ActiveRecord::Migration
  def change
    add_column :tire_models, :product_code, :string
    add_column :tire_models, :construction, :string
    add_column :tire_models, :weight, :float
    add_column :tire_models, :warranty_miles, :integer
    add_column :tire_models, :tire_code, :string
  end
end
