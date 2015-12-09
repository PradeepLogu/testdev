class DBMailInterceptor
	def self.delivering_email(message)

		logger = Logger.new("log/email.log")
		logger.info("#{message.from.first}	#{message.to.first}	#{message.subject}	#{message.text_part.to_s}")

		message.methods.each do |m|
			logger.info("-->#{m.to_s}")
		end
	end
end