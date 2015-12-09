class AddCurrencyToTireListings < ActiveRecord::Migration
  def change
    add_column :tire_listings, :currency, :string, :default => 'USD'
  end
end
