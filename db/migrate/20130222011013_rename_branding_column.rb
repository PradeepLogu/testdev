class RenameBrandingColumn < ActiveRecord::Migration
  def change
  	rename_column :assets, :brandings_id, :branding_id
  end
end
