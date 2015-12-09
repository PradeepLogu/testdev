class AddFinancialInfoToAccountsAndTireStores < ActiveRecord::Migration
  def change
	add_column :accounts, :financial_info, :hstore
	add_column :tire_stores, :financial_info, :hstore
  end
end
