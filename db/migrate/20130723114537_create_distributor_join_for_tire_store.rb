class CreateDistributorJoinForTireStore < ActiveRecord::Migration
	def change
		create_table :tire_stores_distributors do |t|
			t.integer :tire_store_id
			t.integer :distributor_id
			t.hstore :tire_manufacturers
			t.integer :frequency_days
			t.datetime :next_run_time
			t.datetime :last_run_time
			t.integer :records_created
			t.integer :records_updated
			t.integer :records_untouched
			t.integer :records_deleted

			t.timestamps
		end

		add_index :tire_stores_distributors, [:tire_store_id]
		add_index :tire_stores_distributors, [:distributor_id]
	end
end