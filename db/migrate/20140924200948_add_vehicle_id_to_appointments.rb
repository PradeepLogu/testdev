class AddVehicleIdToAppointments < ActiveRecord::Migration
  def change
  	add_column :appointments, :auto_year_id, :integer, :null => true
  	add_column :appointments, :auto_option_id, :integer, :null => true
  	add_column :appointments, :auto_model_id, :integer, :null => true
  	add_column :appointments, :auto_manufacturer_id, :integer, :null => true
  	add_column :appointments, :vehicle_mileage, :string, :null => true
  end
end
