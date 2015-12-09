class AddTgpModelIdToTireModels < ActiveRecord::Migration
  def change
  	add_column :tire_models, :tgp_model_id, :integer, :default => 0
  end
end
