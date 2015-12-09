class AddModelIdToTireListing < ActiveRecord::Migration
  def change
    add_column :tire_listings, :tire_model_id, :integer
  end
end
