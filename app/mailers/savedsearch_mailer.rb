class SavedsearchMailer < ActionMailer::Base
    default from: "mail@treadhunter.com"
    
	def saved_search_email(tire_search)
		@tire_search = tire_search
		mail(:to => tire_search.user.email,
		     :subject => "We found new tires for you!")
	end

	def saved_search_text(tire_search)
		@tire_search = tire_search
		mail(:to => 'admin@treadhunter.com', subject: 'not used')
	end
end
