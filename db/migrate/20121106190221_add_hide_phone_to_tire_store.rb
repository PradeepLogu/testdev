class AddHidePhoneToTireStore < ActiveRecord::Migration
  def change
    add_column :tire_stores, :hide_phone, :boolean, :default => false
  end
end
