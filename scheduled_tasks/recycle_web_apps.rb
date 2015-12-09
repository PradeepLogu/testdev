require 'heroku-api'

class RecycleWeb1 < Scheduler::SchedulerTask
  environments :all
  # environments :staging, :production
  
  every '24h'
  
  def run
    begin
      heroku = Heroku::API.new
      #heroku.post_ps_restart('deep-stream-8407', 'ps' => 'web.1') 
      ActionMailer::Base.mail(:from => "mail@treadhunter.com", 
        :to => system_process_completion_email_address(), 
        :subject => "Cycled Web.1", 
        :body => "Recycled web.1 process.").deliver      
    rescue Exception => e
      ActionMailer::Base.mail(:from => "mail@treadhunter.com", 
        :to => system_process_completion_email_address(), 
        :subject => "Error Cycling Web.1", 
        :body => e.to_s).deliver
    end
  end
end