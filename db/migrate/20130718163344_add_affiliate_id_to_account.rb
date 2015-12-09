class AddAffiliateIdToAccount < ActiveRecord::Migration
  def change
    add_column :accounts, :affiliate_id, :integer, :default => -1, :null => false
    add_column :accounts, :affilate_time, :date
    add_column :accounts, :affiliate_referrer, :string
  end
end
