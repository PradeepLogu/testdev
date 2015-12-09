class CreatePushMessageDetails < ActiveRecord::Migration
  def up
    create_table :push_message_details do |t|
      #t.string    :app,                   :null => false
      t.string    :device,                :null => false
      #t.string    :type,                  :null => false
      t.text      :properties,            :null => true

      t.string    :guid,                  :null => false
      t.integer   :push_message_id,       :null => false
      t.integer	  :tire_store_id,         :null => false
      t.boolean   :has_been_read,         :null => false, :default => false
      t.timestamp :last_read_date,        :null => true

      #t.boolean   :delivered,             :null => false, :default => false
      #t.timestamp :delivered_at,          :null => true
      #t.boolean   :failed,                :null => false, :default => false
      #t.timestamp :failed_at,             :null => true
      #t.integer   :error_code,            :null => true
      #t.string    :error_description,     :null => true
      #t.timestamp :deliver_after,         :null => true

      t.timestamps
    end

    add_index :push_message_details, [:guid]
    add_index :push_message_details, [:push_message_id]
    add_index :push_message_details, [:has_been_read, :last_read_date]
  end

  def down
    drop_table :push_message_details
  end
end
