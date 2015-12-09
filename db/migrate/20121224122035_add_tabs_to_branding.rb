class AddTabsToBranding < ActiveRecord::Migration
  def change
    add_column :brandings, :tab1title, :string
    add_column :brandings, :tab1content, :text
    add_column :brandings, :tab2title, :string
    add_column :brandings, :tab2content, :text
    add_column :brandings, :tab3title, :string
    add_column :brandings, :tab3content, :text
    add_column :brandings, :tab4title, :string
    add_column :brandings, :tab4content, :text
    add_column :brandings, :tab5title, :string
    add_column :brandings, :tab5content, :text
  end
end
