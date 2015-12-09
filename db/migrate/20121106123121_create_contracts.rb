class CreateContracts < ActiveRecord::Migration
  def change
    create_table :contracts do |t|
      t.integer :account_id
      t.date :expiration_date
      t.integer :contract_amount
      t.boolean :can_post_listings
      t.boolean :can_use_mobile
      t.boolean :can_use_logo
      t.boolean :can_use_branding
      t.boolean :can_have_search_portal
      t.boolean :can_have_filter_portal
      t.integer :max_monthly_listings

      t.timestamps
    end
  end
end
