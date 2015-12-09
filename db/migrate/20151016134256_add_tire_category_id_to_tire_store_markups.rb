class AddTireCategoryIdToTireStoreMarkups < ActiveRecord::Migration
  def change
    add_column :tire_store_markups, :tire_category_id, :integer
  end
end
