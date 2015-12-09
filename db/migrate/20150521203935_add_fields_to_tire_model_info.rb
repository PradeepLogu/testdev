class AddFieldsToTireModelInfo < ActiveRecord::Migration
  def change
  	add_column :tire_model_infos, :tgp_model_id, :integer, :default => 0
  	add_column :tire_model_infos, :tgp_features, :hstore
  	add_column :tire_model_infos, :tgp_benefits, :hstore
  	add_column :tire_model_infos, :tgp_other_attributes, :hstore
  end
end
