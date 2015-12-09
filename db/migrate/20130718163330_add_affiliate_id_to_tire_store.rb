class AddAffiliateIdToTireStore < ActiveRecord::Migration
  def change
    add_column :tire_stores, :affiliate_id, :integer, :default => -1, :null => false
    add_column :tire_stores, :affilate_time, :date
    add_column :tire_stores, :affiliate_referrer, :string
  end
end
