class ContactsellerMailer < ActionMailer::Base
 	#default from: "mailer@treadhunter.com"
 
	def contact_notification(sender)
		@sender = sender

		@tire_store = TireStore.find(sender.tire_store_id)
		if @tire_store
			mail(:to => system_problem_email_address(),
				#:to => @tire_store.contact_email,
				:bcc => system_problem_bcc_email_address(),
		     	:from => 'mail@treadhunter.com', #sender.email,
		     	:subject => "New Customer Inquiry (#{@tire_store.contact_email})")
		end
	end
end
