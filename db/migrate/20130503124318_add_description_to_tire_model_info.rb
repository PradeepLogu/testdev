class AddDescriptionToTireModelInfo < ActiveRecord::Migration
  def change
    add_column :tire_model_infos, :description, :string
  end
end
