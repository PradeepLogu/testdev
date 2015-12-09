class SavedSearchManager
	def process()
		daily_searches = TireSearch.find(:all, 
			:conditions => ["saved_search_frequency ilike 'd%' and user_id > 0 and updated_at <= ?", Time.now - 1.days])
		weekly_searches = TireSearch.find(:all, 
			:conditions => ["saved_search_frequency ilike 'w%' and user_id > 0 and updated_at <= ?", Time.now - 1.week])

		# now we have possible matches...let's process these and see which ones have new listings
		daily_searches.each do |s|
			s.only_fresh = true
			s.max_recs = 25
			if s.tirelistings.count > 0
				# this one has matches - let's send an email
				puts "DAILY: Sending email - #{s.user.email}, #{s.tirelistings.count} listings found."
				send_email_for_search(s)
			else
				puts "DAILY: NOT Sending email - #{s.user.email}, #{s.tirelistings.count} listings found."
			end
		end	
		weekly_searches.each do |s|
			s.only_fresh = true
			s.max_recs = 25
			if s.tirelistings.count > 0
				# this one has matches - let's send an email
				puts "WEEKLY: Sending email - #{s.user.email}, #{s.tirelistings.count} listings found."
				send_email_for_search(s)
			else
				puts "WEEKLY: NOT Sending email - #{s.user.email}, #{s.tirelistings.count} listings found."
			end
		end
	end

	def send_email_for_search(tire_search)
		# send the email
		if tire_search.send_text
			text_msg = SavedsearchMailer.saved_search_text(tire_search)
			ts = TextSender.new()
			puts "Sending text - #{text_msg.body.to_s}"
			ts.send_text(tire_search.text_phone, text_msg.body.to_s)
		else
			SavedsearchMailer.saved_search_email(tire_search).deliver()
		end

		# touch the updated_at date so we only get fresh ones next time
		tire_search.update_attribute(:updated_at, Time.now)
	end
end