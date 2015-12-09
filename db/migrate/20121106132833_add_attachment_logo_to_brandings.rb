class AddAttachmentLogoToBrandings < ActiveRecord::Migration
  def self.up
    change_table :brandings do |t|
      t.has_attached_file :logo
    end
  end

  def self.down
    drop_attached_file :brandings, :logo
  end
end
