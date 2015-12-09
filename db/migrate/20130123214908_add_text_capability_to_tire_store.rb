class AddTextCapabilityToTireStore < ActiveRecord::Migration
  def change
    add_column :tire_stores, :send_text, :boolean, :default => false
    add_column :tire_stores, :text_phone, :string
  end
end
