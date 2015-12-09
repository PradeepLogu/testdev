class AddSavedSearchFrequencyToTireSearch < ActiveRecord::Migration
  def change
    add_column :tire_searches, :saved_search_frequency, :string
  end
end
