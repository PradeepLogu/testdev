class AddAttachmentPhoto1Photo2Photo3Photo4ToTireListings < ActiveRecord::Migration
  def self.up
    change_table :tire_listings do |t|
      t.has_attached_file :photo1
      t.has_attached_file :photo2
      t.has_attached_file :photo3
      t.has_attached_file :photo4
    end
  end

  def self.down
    drop_attached_file :tire_listings, :photo1
    drop_attached_file :tire_listings, :photo2
    drop_attached_file :tire_listings, :photo3
    drop_attached_file :tire_listings, :photo4
  end
end
