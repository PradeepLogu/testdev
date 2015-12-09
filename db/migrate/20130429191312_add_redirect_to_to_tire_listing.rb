class AddRedirectToToTireListing < ActiveRecord::Migration
  def change
    add_column :tire_listings, :redirect_to, :string
  end
end
