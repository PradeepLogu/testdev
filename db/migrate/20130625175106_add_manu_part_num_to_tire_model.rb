class AddManuPartNumToTireModel < ActiveRecord::Migration
  def change
  	add_column :tire_models, :manu_part_num, :string
  end
end
