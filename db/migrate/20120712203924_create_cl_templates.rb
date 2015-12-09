class CreateClTemplates < ActiveRecord::Migration
  def change
    create_table :cl_templates do |t|
      t.integer :tire_store_id, :default => 0
      t.integer :account_id, :default => 0
      t.string :title
      t.string :body, :limit => 4096

      t.timestamps
    end
  end
end
