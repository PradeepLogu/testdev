class ChangeTireModelInfoDescriptionToText < ActiveRecord::Migration
  def change
  	change_column :tire_model_infos, :description, :text
  end
end
