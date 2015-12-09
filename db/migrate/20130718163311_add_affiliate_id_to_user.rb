class AddAffiliateIdToUser < ActiveRecord::Migration
  def change
    add_column :users, :affiliate_id, :integer, :default => -1, :null => false
    add_column :users, :affilate_time, :date
    add_column :users, :affiliate_referrer, :string
  end
end
