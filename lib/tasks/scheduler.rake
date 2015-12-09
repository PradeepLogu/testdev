# This should run once an hour
desc "This task is called by the Heroku scheduler add-on"
task :run_saved_searches => :environment do
	puts "Running saved searches"
	s = SavedSearchManager.new
	s.process
	puts "done."
end

task :billing => :environment do
	s = BillingManager.new
	s.process
end

task :followup => :environment do
  s = FollowupManager.new
  s.process
end

# need to add delayed_job here, run it every 15 minutes
task :do_nothing => :environment do
  #User.send_reminders
end

task :keep_alive => :environment do
   uri = URI.parse('http://beta.treadhunter.com/')
   Net::HTTP.get(uri)
end

task :update_google_places => :environment do 
	@email_content = TireStore.set_all_google_place_ids
	if @email_content.nil? || @email_content.size == 0
    	ActionMailer::Base.mail(:from => "mail@treadhunter.com", 
            :to => system_process_completion_email_address(), 
            :subject => "Processed Google Places - everything OK", 
            :body => "No action needed").deliver

	else
		puts "sending email..."
    	ActionMailer::Base.mail(:from => "mail@treadhunter.com", 
            :to => system_process_completion_email_address(), 
            :subject => "Processed Google Places", 
            :body => @email_content.join("\n")).deliver
    end
end

task :update_google_ratings => :environment do 
	@total_updated, @total_not_updated = TireStore.update_google_data_older_than(24)

	ActionMailer::Base.mail(:from => "mail@treadhunter.com", 
        :to => system_process_completion_email_address(), 
        :subject => "Updated Google Ratings - #{@total_updated} were updated, #{@total_not_updated} left alone", 
        :body => "#{@total_updated} were updated, #{@total_not_updated} left alone").deliver
end

task :run_tci_update => :environment do
	@scraper = TCIInterface.new()

	@tci = Distributor.find_by_distributor_name_and_city('Tire Centers, LLC', 'Norcross')
	@tci.ready_for_scrape.each do |xref|
		@scraper.delay.import_tire_store_data(xref.tire_store)
	end
end