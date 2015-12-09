class AddDevices < ActiveRecord::Migration
	def change
		create_table :devices do |t|
			t.integer	:user_id,		:null => false
			t.string    :token,			:null => false
			t.boolean 	:enabled,		:null => false, :default => true 
			t.string	:platform
			t.timestamps
		end
	end
end
