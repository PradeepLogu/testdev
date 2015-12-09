class AddTemplateNumberToBrandings < ActiveRecord::Migration
  def change
    add_column :brandings, :template_number, :integer, :default => 1
  end
end
