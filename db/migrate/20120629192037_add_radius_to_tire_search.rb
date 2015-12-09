class AddRadiusToTireSearch < ActiveRecord::Migration
  def change
  	add_column :tire_searches, :radius, :integer, :default => 20
  end
end
