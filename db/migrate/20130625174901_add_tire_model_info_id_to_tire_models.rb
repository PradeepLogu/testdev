class AddTireModelInfoIdToTireModels < ActiveRecord::Migration
  def change
  	add_column :tire_models, :tire_model_info_id, :integer, :default => -1
  end
end
