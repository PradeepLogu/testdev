class Asset < ActiveRecord::Base
	attr_accessible :image, :url, :caption, :branding_id
	belongs_to :branding
	has_attached_file :image, :styles => { :thumb => "100x100>" }
	has_many :asset_usages

	include Rails.application.routes.url_helpers

	def to_jq_upload
	{
		"name" => read_attribute(:image_file_name),
		"size" => read_attribute(:image_file_size),
		"url" => image.url(:original),
		"delete_url" => asset_path(self),
		"delete_type" => "DELETE" 
	}
	end

	def valid_uses
		['Storefront', 'Promotions']
	end

	def has_usage(usage_name)
		!AssetUsage.find_by_asset_id_and_usage_name(self.id, usage_name).nil?
	end

	def create_usage(usage_name)
		if valid_uses.include?(usage_name)
			AssetUsage.find_or_create_by_asset_id_and_branding_id_and_tire_store_id_and_usage_name(self.id, self.branding_id, self.branding.tire_store_id, usage_name)
		end
	end

	def delete_usage(usage_name)
		u = AssetUsage.find_by_asset_id_and_usage_name(self.id, usage_name)
		if u
			u.delete()
		end
	end
end
