class AddFieldsToTireModel < ActiveRecord::Migration
  def change
  	add_column :tire_models, :ply, :string
  	add_column :tire_models, :diameter, :string
  	add_column :tire_models, :revs_per_mile, :string
  	add_column :tire_models, :min_rim_width, :float
  	add_column :tire_models, :max_rim_width, :float
  	add_column :tire_models, :single_max_load_pounds, :integer
  	add_column :tire_models, :dual_max_load_pounds, :integer
  	add_column :tire_models, :single_max_psi, :integer
  	add_column :tire_models, :dual_max_psi, :integer
  	add_column :tire_models, :section_width, :float
  	add_column :tire_models, :weight_pounds, :float
  	add_column :tire_models, :active, :boolean
  	add_column :tire_models, :embedded_speed, :string
  	add_column :tire_models, :load_description, :string
  	add_column :tire_models, :tgp_category_id, :integer
	add_column :tire_models, :run_flat_id, :integer
	add_column :tire_models, :tgp_tire_type_id, :integer
	add_column :tire_models, :dual_load_index, :string
	add_column :tire_models, :suffix, :string
  end
end
