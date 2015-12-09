class DropDupeFieldAddPromoUrlToPromotions < ActiveRecord::Migration
  def change
  	remove_column :promotions, :promo_name
    add_column :promotions, :promo_url, :string
  end
end
