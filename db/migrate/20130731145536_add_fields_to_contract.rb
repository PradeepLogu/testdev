class AddFieldsToContract < ActiveRecord::Migration
  def change
    add_column :contracts, :bill_cc, :boolean
    add_column :contracts, :billing_type, :integer
  end
end
