class TirestorescraperMailer < ActionMailer::Base
 	#default from: "mailer@treadhunter.com"
 
	def scrape_done(email, key, cities, state, log, status, google_url, yp_url)
		@key = key
		@cities = cities
		@state = state
		@status = status
		@log = log
		@google_url = google_url
		@yp_url = yp_url
		mail(:to => email,
			:from => 'mail@treadhunter.com', #sender.email,
			:bcc => system_problem_cc_email_address(),
			:subject => "Scrape is done - status #{status}")
	end
end
