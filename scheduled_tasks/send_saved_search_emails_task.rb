class SendSavedSearchEmailsTask < Scheduler::SchedulerTask
  environments :all
  # environments :staging, :production
  
  every '24h', :first_at => Chronic.parse('next midnight')
  # other examples:
  # every '24h', :first_at => Chronic.parse('next midnight')
  # cron '* 4 * * *'  # cron style
  # in '30s'          # run once, 30 seconds from scheduler start/restart
  
  
  def run
    # Your code here, eg:     task execute: :environment do
    s = SavedSearchManager.new
    s.process
    
    # use log() for writing to scheduler daemon log
    log("Saved searches processed.")
    ActionMailer::Base.mail(:from => "mail@treadhunter.com", 
      :to => system_process_completion_email_address(), 
      :subject => "Saved Searches processed.", 
      :body => "Ran saved search process.").deliver
  end
end