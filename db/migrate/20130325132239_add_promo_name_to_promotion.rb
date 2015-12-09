class AddPromoNameToPromotion < ActiveRecord::Migration
  def change
    add_column :promotions, :promo_name, :string
  end
end
