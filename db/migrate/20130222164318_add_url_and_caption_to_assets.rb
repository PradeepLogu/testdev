class AddUrlAndCaptionToAssets < ActiveRecord::Migration
  def change
    add_column :brandings, :url, :string
    add_column :brandings, :caption, :string
  end
end
