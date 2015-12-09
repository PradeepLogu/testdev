class AddNotifications < ActiveRecord::Migration
	def change
		create_table :notifications do |t|
			t.integer :user_id
			t.integer :account_id
			t.boolean :admin_only 
			t.boolean :super_user_only
			t.datetime :expiration_date 
			t.integer :remaining_views
			t.string :message
			t.string :title 
			t.boolean :sticky 
			t.integer :visible_time 
			t.string :image

			t.timestamps
		end

		add_index :notifications, [:user_id]
		add_index :notifications, [:account_id]
		add_index :notifications, [:expiration_date]
	end
end
