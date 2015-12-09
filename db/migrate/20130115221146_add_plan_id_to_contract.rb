class AddPlanIdToContract < ActiveRecord::Migration
  def change
    add_column :contracts, :plan_id, :integer
    remove_column :contracts, :can_post_listings
    remove_column :contracts, :can_use_mobile
    remove_column :contracts, :can_use_logo
    remove_column :contracts, :can_use_branding
    remove_column :contracts, :can_have_search_portal
    remove_column :contracts, :can_have_filter_portal
  end
end
