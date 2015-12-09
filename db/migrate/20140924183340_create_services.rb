class CreateServices < ActiveRecord::Migration
  def up
    create_table :services do |t|
      t.string    :service_name,                  :null => false
      t.timestamps
    end  
  end

  def down
  	drop_table :services
  end
end

