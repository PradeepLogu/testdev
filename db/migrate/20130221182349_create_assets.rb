class CreateAssets < ActiveRecord::Migration
  def change
    create_table :assets do |t|
  		t.attachment :image
  		t.integer :brandings_id

     	t.timestamps
    end
  end
end
