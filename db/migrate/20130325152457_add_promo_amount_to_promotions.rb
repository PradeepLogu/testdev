class AddPromoAmountToPromotions < ActiveRecord::Migration
  def change
    add_column :promotions, :promo_amount, :float
  end
end
