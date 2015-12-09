class AddBillingEmailToAccount < ActiveRecord::Migration
  def change
    add_column :accounts, :billing_email, :string
  end
end
