class CreateDistributors < ActiveRecord::Migration
  def change
    create_table :distributors do |t|
      t.string :distributor_name
      t.string :address
      t.string :city
      t.string :state
      t.string :zipcode
      t.string :contact_name
      t.string :contact_email

      t.timestamps
    end
  end
end
