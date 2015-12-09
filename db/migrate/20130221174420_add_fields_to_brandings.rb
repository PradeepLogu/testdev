class AddFieldsToBrandings < ActiveRecord::Migration
  def change
    add_column :brandings, :fb_page, :string
    add_column :brandings, :twitter, :string
  end
end
