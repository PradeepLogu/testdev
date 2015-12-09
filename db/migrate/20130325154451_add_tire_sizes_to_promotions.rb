class AddTireSizesToPromotions < ActiveRecord::Migration
  def change
    add_column :promotions, :tire_sizes, :hstore
  end
end
