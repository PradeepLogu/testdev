class AddBillDateToContracts < ActiveRecord::Migration
  def change
    add_column :contracts, :bill_date, :datetime
  end
end
