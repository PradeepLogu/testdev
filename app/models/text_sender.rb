require 'nexmo'

class NexmoError
	attr_accessor :account_id, :from, :to, :body, :date_received, :error_code
	attr_accessor :error_code_label

	def initialize(err_hash)
		@account_id = err_hash["account_id"]
		@from = err_hash["from"]
		@to = err_hash["to"]
		@body = err_hash["body"]
		@date_received = err_hash["date-received"]
		@error_code = err_hash["error-code"]
		@error_code_label = err_hash["error-code-label"]
	end
end

class TextSender
	attr_accessor :nexmo

	def send_text(to_number, text)
		result = true
		begin
			@nexmo ||= create_sender()

			to_number = formatted_number(to_number)

			if get_rejections(to_number).count < 3
				x = @nexmo.send_message!({:to => to_number, :from => '17709274598', :text => text})
			else
				puts "*** NOT SENDING TO #{to_number} because of rejection count"
				result = false
			end

		rescue Exception => e
			result = false
			puts e.to_s
		end

		result
	end

	def create_sender()
		Nexmo::Client.new(ENV['NEXMO_KEY'], ENV['NEXMO_SECRET'])
	end

	def get_rejections(to_number)
		result = []
		@nexmo ||= create_sender()

		# check a week's worth of rejections
		(0..6).each do |i|
			d = i.day.ago.to_date

			response = @nexmo.get_message_rejections(:date => d.to_s, :to => to_number)

			if response.ok? && response.object["items"]
				response.object["items"].each do |h|
					err = NexmoError.new(h)
					result << err unless err.error_code = "15"
				end
			end
		end
		result
	end

	def formatted_number(to_number)
		if to_number.size < 10
			raise "Invalid to number: #{to_number}"
		else
			if !to_number.starts_with?("1")
				return "1" + to_number
			else
				return to_number
			end
		end
	end
end