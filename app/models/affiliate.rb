class Affiliate < ActiveRecord::Base
	is_impressionable

	attr_accessible :address, :affilate_tag, :city, :contact_email, :contact_name, :name, :state, :zipcode

	def hits_by_date(query_date)
		Impression.count(:conditions => ['impressionable_type = ? and impressionable_id = ? and created_at >= ? and created_at < ?', 'Affiliate', self.id, query_date.beginning_of_day, query_date.end_of_day])
	end
end
