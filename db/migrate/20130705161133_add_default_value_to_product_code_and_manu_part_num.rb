class AddDefaultValueToProductCodeAndManuPartNum < ActiveRecord::Migration
  def change
  	change_column :tire_models, :product_code, :string, :default => ''
  	change_column :tire_models, :manu_part_num, :string, :default => ''
  end
end
