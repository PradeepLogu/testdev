class AddFieldsForNewListingsToClTemplates < ActiveRecord::Migration
  def change
	add_column :cl_templates, :title_new_listings, :string
	add_column :cl_templates, :body_new_listings, :string, :limit => 4096
  end
end
