class AddTextToSavedSearch < ActiveRecord::Migration
  def change
    add_column :tire_searches, :send_text, :boolean, :default => false
    add_column :tire_searches, :text_phone, :string
  end
end
