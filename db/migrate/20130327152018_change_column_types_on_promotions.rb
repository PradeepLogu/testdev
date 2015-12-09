class ChangeColumnTypesOnPromotions < ActiveRecord::Migration
  def change
  	change_column :promotions, :promotion_type, :string
  	add_column :promotions, :new_or_used, :string
  end
end
