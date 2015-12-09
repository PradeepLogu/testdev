class AddLongitudeToTireStore < ActiveRecord::Migration
  def change
    add_column :tire_stores, :longitude, :float
  end
end
