class AddPromoAmountMinToPromotions < ActiveRecord::Migration
  def change
  	remove_column :promotions, :promo_amount
    add_column :promotions, :promo_amount_min, :float
    add_column :promotions, :promo_amount_max, :float
  end
end
