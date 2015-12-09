class PushMessageDetail < ActiveRecord::Base
    store :properties, accessors: [:attributes_for_device, :content_available]
    attr_accessible :device, :attributes_for_device, :content_available, :guid
    attr_accessible :push_message_id, :tire_store_id, :has_been_read, :last_read_date

	after_initialize :make_methods

	#def as_json(options)
	#	super({:methods => [push_message.type.to_json]}.merge(options))
	#end

    #has_one Push::Message

    def push_message
    	@push_message ||= Push::Message.find_by_id(push_message_id)
    end

    def tire_store_id
    	@tire_store_id ||= begin
			JSON.parse(self.push_message.properties[:attributes_for_device])["tire_store_id"]
    	rescue Exception => e
    		self.properties[:attributes_for_device][:tire_store_id]
    	end
    end

    def app
    	push_message.app
    end

    def type
    	push_message.type
    end

	def make_methods
		# first remove all others
		self.methods.grep(/_afd$|_prop$|_origafd$|_origprop$/).each do |m|
			self.class.send(:remove_method, m)
		end
		
		self.properties.keys.each do |k|
			if k.to_s != "attributes_for_device"
				self.class.send(:define_method, "#{k}_prop") { return self.properties[k] } 
			end
		end

		self.properties[:attributes_for_device].keys.each do |k|
			self.class.send(:define_method, "#{k}_afd") { return self.properties[:attributes_for_device][k]}
		end

		if !push_message.nil?
			push_message.properties.keys.each do |k|
				if k.to_s != "attributes_for_device"
					if !self.respond_to?("#{k}_prop") && !self.respond_to?("#{k}")
						self.class.send(:define_method, "#{k}_prop") { return push_message.properties[k] } 
					end
				end
			end

			JSON.parse(push_message.properties[:attributes_for_device]).keys.each do |k|
				if !self.respond_to?("#{k}_afd") && !self.respond_to?("#{k}")
					self.class.send(:define_method, "#{k}_afd") { return JSON.parse(push_message.properties[:attributes_for_device])[k]}
				end
			end
		end
	end

	def as_json(options={})
		#  :include => [@notification.methods.grep(/^afd_|^prop_/)]
		super(options.merge(:except => :properties, :methods => self.methods.grep(/_afd$|_prop$|_origafd$|_origprop$/)))
	end
end