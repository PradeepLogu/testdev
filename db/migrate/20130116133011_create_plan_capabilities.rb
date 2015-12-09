class CreatePlanCapabilities < ActiveRecord::Migration
  def change
    create_table :plan_capabilities do |t|
      t.integer :plan_id
      t.integer :capability_id

      t.timestamps
    end
  end
end
