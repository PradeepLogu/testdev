class AddPromoLevelToPromotions < ActiveRecord::Migration
  def change
    add_column :promotions, :promo_level, :string
  end
end
