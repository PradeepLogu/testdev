class AddStartDateToContract < ActiveRecord::Migration
  def change
    add_column :contracts, :start_date, :date
  end
end
