class AddTireModelToTireSearch < ActiveRecord::Migration
  def change
    add_column :tire_searches, :tire_model_id, :integer
  end
end
