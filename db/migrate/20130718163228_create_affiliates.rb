class CreateAffiliates < ActiveRecord::Migration
  def change
    create_table :affiliates do |t|
      t.string :name
      t.string :address
      t.string :city
      t.string :state
      t.string :zipcode
      t.string :affilate_tag
      t.string :contact_name
      t.string :contact_email

      t.timestamps
    end
  end
end
