class AddLocationToTireSearch < ActiveRecord::Migration
  def change
  	add_column :tire_searches, :locationstr, :string
  	add_column :tire_searches, :latitude, :float
  	add_column :tire_searches, :longitude, :float
  end
end
