class AddFieldsToPromotions < ActiveRecord::Migration
  def change
    add_column :promotions, :promotion_key, :string
  end
end
