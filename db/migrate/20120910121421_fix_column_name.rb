class FixColumnName < ActiveRecord::Migration
  def up
    rename_column :tire_models, :tire_cateogry_id, :tire_category_id
  end

  def down
  end
end
