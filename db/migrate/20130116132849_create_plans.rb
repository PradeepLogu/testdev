class CreatePlans < ActiveRecord::Migration
  def change
    create_table :plans do |t|
      t.string :name
      t.integer :default_num_listings
      t.string :stripe_plan

      t.timestamps
    end
  end
end
