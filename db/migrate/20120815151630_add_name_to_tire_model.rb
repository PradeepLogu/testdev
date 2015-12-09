class AddNameToTireModel < ActiveRecord::Migration
  def change
    add_column :tire_models, :name, :string
  end
end
