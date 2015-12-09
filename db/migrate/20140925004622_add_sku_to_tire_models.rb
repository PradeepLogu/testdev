class AddSkuToTireModels < ActiveRecord::Migration
  def change
  	add_column :tire_models, :skus, :hstore
  end
end
