class RenameMisspelledColumns < ActiveRecord::Migration
  def up
  	rename_column :affiliates, :affilate_tag, :affiliate_tag
  	rename_column :users, :affilate_time, :affiliate_time
  	rename_column :tire_stores, :affilate_time, :affiliate_time
  	rename_column :accounts, :affilate_time, :affiliate_time
  end

  def down
  end
end
