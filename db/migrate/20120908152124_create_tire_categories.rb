class CreateTireCategories < ActiveRecord::Migration
  def change
    create_table :tire_categories do |t|
      t.string :category_name
      t.string :category_type

      t.timestamps
    end
  end
end
