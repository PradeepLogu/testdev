class ContactusMailer < ActionMailer::Base
 	#default from: "mailer@treadhunter.com"
 
	def support_notification(sender)
		@sender = sender
		mail(:to => contact_us_support_email_address(),
		     :from => 'mail@treadhunter.com', #sender.email,
		     :subject => "New #{sender.support_type}")
	end

	def generic_email(sender, to_addresses, subject)
		@sender = sender
		@subject = subject
		mail(:to => to_addresses,
		     :from => 'mail@treadhunter.com', #sender.email,
		     :subject => subject)
	end
end
