class AddUrlAndCaptionToAssetsTake2 < ActiveRecord::Migration
  def change
    add_column :assets, :url, :string
    add_column :assets, :caption, :string
  end
end
