class AddSloganAndDescriptionToBranding < ActiveRecord::Migration
  def change
    add_column :brandings, :slogan, :string
    add_column :brandings, :slogan_description, :string
  end
end
