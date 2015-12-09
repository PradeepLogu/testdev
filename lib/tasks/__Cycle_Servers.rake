require 'heroku-api'

def cycle_process(proc_num)
	begin
		if ((Time.now.hour % 7) == proc_num) # run every hour, but only cycle one each time
			heroku = Heroku::API.new
			puts "Cycling web.#{proc_num}"
			heroku.post_ps_restart('deep-stream-8407', 'ps' => "web.#{proc_num}")
			ActionMailer::Base.mail(:from => "mail@treadhunter.com", 
				:to => system_process_completion_email_address(), 
				:subject => "Cycled Web.#{proc_num}", 
				:body => "Recycled web.#{proc_num} process.").deliver      
		end
	rescue Exception => e
		ActionMailer::Base.mail(:from => "mail@treadhunter.com", 
			:to => system_process_completion_email_address(), 
			:subject => "Error Cycling Web.#{proc_num}", 
			:body => e.to_s).deliver
	end
end

namespace :CycleServer do
    desc "Recycle Web.1 process"
    task web1: :environment do
		cycle_process(1)
	end

    task web2: :environment do
		cycle_process(2)
	end

    task web3: :environment do
		cycle_process(3)
	end

    task web4: :environment do
		cycle_process(4)
	end

    task web5: :environment do
		cycle_process(5)
	end

	task all: :environment do
		cycle_process(1)
		sleep 60
		cycle_process(2)
		sleep 60
		cycle_process(3)
		sleep 60
		cycle_process(4)
		sleep 60
		cycle_process(5)
		sleep 60
		cycle_process(6)
		sleep 60
		cycle_process(7)
	end
end