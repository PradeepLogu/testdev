class AddContactEmailToTireStores < ActiveRecord::Migration
  def change
    add_column :tire_stores, :contact_email, :string
  end
end
