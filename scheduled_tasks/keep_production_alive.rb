require 'rest_client'

class KeepProductionAlive < Scheduler::SchedulerTask
  environments :all
  # environments :staging, :production
  
  every '30s'
  # other examples:
  # every '24h', :first_at => Chronic.parse('next midnight')
  # cron '* 4 * * *'  # cron style
  # in '30s'          # run once, 30 seconds from scheduler start/restart
  
  
  def run
    # Your code here, eg:     task execute: :environment do
    beta_response = RestClient.get 'http://beta.treadhunter.com'
    prod_response = RestClient.get 'http://www.treadhunter.com'
    
    # use log() for writing to scheduler daemon log
    log("Beta response: #{beta_response.code}")
    log("Prod response: #{prod_response.code}")
  end
end