class AddOtherPropertiesToUsers < ActiveRecord::Migration
  def change
  	add_column :users, :other_properties, :hstore
  end
end
