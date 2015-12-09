class AddDowToTireSearches < ActiveRecord::Migration
  def change
    add_column :tire_searches, :saved_search_dow, :integer
  end
end
