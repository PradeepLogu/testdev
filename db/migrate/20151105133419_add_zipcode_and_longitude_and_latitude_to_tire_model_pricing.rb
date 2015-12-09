class AddZipcodeAndLongitudeAndLatitudeToTireModelPricing < ActiveRecord::Migration
  def change
    add_column :tire_model_pricings, :zipcode, :integer
    add_column :tire_model_pricings, :longitude, :decimal
    add_column :tire_model_pricings, :latitude, :decimal
  end
end
