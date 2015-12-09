class AddNewOrUsedToTireSearch < ActiveRecord::Migration
  def change
    add_column :tire_searches, :new_or_used, :string, :default => 'b'
  end
end
