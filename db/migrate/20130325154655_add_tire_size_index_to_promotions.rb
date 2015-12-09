class AddTireSizeIndexToPromotions < ActiveRecord::Migration
  def change
	execute "CREATE INDEX promotions_tire_size_ids ON promotions USING GIN(tire_sizes)"
  end
end
