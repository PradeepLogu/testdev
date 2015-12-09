class RemoveUrlAndCaptionFromBrandings < ActiveRecord::Migration
  def change
    remove_column :brandings, :url
    remove_column :brandings, :caption
  end
end
