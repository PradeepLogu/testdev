class Event
	attr_accessor :title, :start, :end, :allDay

	def initialize(attributes = {})
		attributes.each do |key, value|
			self.send("#{key}=", value)
		end
		@attributes = attributes
	end
end