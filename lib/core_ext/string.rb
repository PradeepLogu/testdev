class String
	def is_number?
		true if Integer(self) rescue false
	end

	def is_positive_number?
		self.is_number? && Integer(self) > 0
	end

	def is_valid_email?
		begin
			parser = Mail::RFC2822Parser.new
			parser.root = :addr_spec
			result = parser.parse(self)

			# Don't allow for a TLD by itself list (sam@localhost)
			# The Grammar is: (local_part "@" domain) / local_part ... discard latter
			result && 
				result.respond_to?(:domain) && 
				result.domain.dot_atom_text.elements.size > 1
		rescue
			return false
		end	
	end

	def to_bool
		return true if self == true || self =~ (/(true|t|yes|y|1)$/i)
		return false if self == false || self.blank? || self =~ (/(false|f|no|n|0)$/i)
		return false
		#raise ArgumentError.new("invalid value for Boolean: \"#{self}\"")
	end
end