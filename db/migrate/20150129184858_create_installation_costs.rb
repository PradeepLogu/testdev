class CreateInstallationCosts < ActiveRecord::Migration
  def change
    create_table :installation_costs do |t|
      t.integer :account_id
      t.integer :tire_store_id
      t.integer :ea_install_price
      t.float :min_wheel_diameter
      t.float :max_wheel_diameter
      t.hstore :other_properties

      t.timestamps
    end
  end
end
