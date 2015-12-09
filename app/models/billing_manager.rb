class BillingManager
	def create_notification(account, notification_type, message)
		query = "INSERT INTO impressions (impressionable_type, impressionable_id, action_name, created_at, updated_at) VALUES ('#{self.class.name}',#{account.id},'#{notification_type}','#{Time.now}','#{Time.now}');"
		ActiveRecord::Base.connection.execute(query);

		# also create a Notification
		Notification.create_public_account_notification(account.id, message, 
						"Service Notice", 10000, Time.now + 3.days, 5, "notice")
	end

	def has_notification?(account, notification_type)
		return Impression.exists?(['impressionable_type = ? and impressionable_id = ? and action_name = ? and created_at >= ?',
										self.class.name, account.id, notification_type, Time.now - 3.days])
	end

	def process()
		# I don't like this but it's going to be somewhat of a PITA to create the right JOIN
		# statement otherwise.  There should be only a few thousand accounts max anyway...amirite?
		Account.find(:all).each do |acct|
			if !acct.is_private_seller? && acct.need_to_get_credit_card?
				@contract = acct.most_recent_contract
				if !@contract.nil?
					if @contract.is_free_trial_plan?
						# is it about to expire?
						if @contract.expiration_date >= (Time.now + 3.days).to_date &&
							@contract.expiration_date < (Time.now + 7.days).to_date &&
							acct.need_to_get_credit_card?

							# This contract is set to expire in three to seven
							# days.  Let's check to see if we've already sent
							# them a notice.
							if !has_notification?(acct, "three_to_seven")
								# create a notification and send an email.
								create_notification(acct, "three_to_seven", "Your TreadHunter free trial is expiring!")
								BillingMailer.delay.free_trial_expiring(acct)
							end
						elsif @contract.expiration_date < (Time.now + 3.days).to_date &&
							@contract.expiration_date > (Time.now + 0.days).to_date &&
							acct.need_to_get_credit_card?

							# This contract is set to expire in zero to three
							# days.  Let's check to see if we've already sent
							# them a notice.
							if !has_notification?(acct, "zero_to_three")
								# create a notification and send an email.
								create_notification(acct, "zero_to_three", "Your TreadHunter free trial is expiring!")
								BillingMailer.delay.free_trial_expiring(acct)
							end
						elsif @contract.expiration_date < (Time.now + 0.days).to_date
							# this contract has expired, for some reason we don't have 
							# a new non-free contract.
							acct.create_platinum_contract()
						end
					else
						# contract is not a free trial
						# let's see if we are delinquent.
						if acct.stripe_customer_record && acct.stripe_customer_record.delinquent
							if !has_notification?(acct, "delinquent")
								create_notification(acct, "delinquent", "There was a problem with billing<br /><a href='/pages/cc_info'>Click to resolve</a>")
								BillingMailer.delay.billing_problem(acct)
							end
						end
					end
				else
					# this account has never had a contract - should we create one????
				end
			end
		end
	end
end