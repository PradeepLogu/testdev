class Contract < ActiveRecord::Base
  	include ApplicationHelper
  	include ContractsHelper

	attr_accessible :account_id
	attr_accessible :contract_amount
	attr_accessible :plan_id
	attr_accessible :quantity
	attr_accessible :max_monthly_listings
	attr_accessible :start_date
	attr_accessible :expiration_date
	attr_accessible :active

	attr_accessible :bill_cc, :billing_type, :bill_date

	before_save :set_active_flag

	after_create :create_charge

	after_initialize :default_values

	composed_of :contract_amount,
	:class_name  => "Money",
	:mapping     => [%w(contract_amount cents), %w(currency currency_as_string)],
	:constructor => Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
	:converter   => Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }

	belongs_to :account

	belongs_to :plan

	def default_values
		bill_cc = false
		bill_date = nil
	end

	def is_chargeable?
		t = Time.now

		if t <= expiration_date && t >= start_date && bill_date == nil
			return true
		else
			return false
		end
	end

	def expiration_datetime
		self.expiration_date + 1.day - 1.second 
	end

	def create_charge
		if self.bill_cc && is_chargeable?
			puts "OK, we have bill_cc and chargeable..."
			if self.billing_type == BillingTypes::MANUAL_CC_BILLING
				# do we have a card on file?
				if account.need_to_get_credit_card
					puts "**** NO CARD ON FILE ***"
					success = false
				else
					# create a one-time charge
					success = false

					begin
						charge = Stripe::Charge.create(
						  :customer => account.stripe_id,
						  :amount => contract_amount.cents,
						  :currency => "usd",
						  :description => "Charge for #{account.billing_email} %>"
						)

						success = true
						puts "*CHARGED*"
					rescue Exception => e 
						puts "*Exception* #{e.to_s}"
						success = false
					end
				end

				if success
		        	# everything was fine, so let's update the bill date
		        	puts "Updating Bill Date"
		        	self.update_attribute(:bill_date, Time.now)
				end
			elsif self.billing_type == BillingTypes::AUTOMATED_CC_BILLING
				puts "Updating stripe subscription"
				update_stripe_subscription
			else
				puts "Not charging because billing_type is #{self.billing_type}"
			end
		end
	end

	def set_active_flag
		self.active = (self.expiration_date > Time.now && self.start_date <= Time.now)
		true
	end

	def update_stripe_subscription
		result = false
	    
	    puts "Attempting to subscribe to #{self.plan.name} with end date of #{self.start_date}"
		
		if bill_cc
			begin
				###Stripe.api_key = stripe_public_key
        		customer = Stripe::Customer.retrieve(account.stripe_id)
        		if self.start_date > Time.now
	        		customer.update_subscription(:plan => plan.stripe_plan, 
	        										:prorate => true, 
	        										:trial_end => self.start,
	        										:quantity => account.tire_stores.count)
        		else
	        		customer.update_subscription(:plan => plan.stripe_plan, 
	        										:prorate => true, 
	        										:quantity => account.tire_stores.count)
	        	end
        		puts "Successfully updated subscription."
        		result = true
        	rescue Stripe::InvalidRequestError => e 
        		# this is an invalid customer number usually
        		puts "Stripe error: #{e.to_s}"
        		result = false
        	rescue Exception => e
        		puts "General error: #{e.to_s}"
        		result = false
        	end
        else
        	puts "doing nothing, bill_cc is false."
        	result = false
        end

        if result
        	# everything was fine, so let's update the bill date
        	self.update_attribute(:bill_date, Time.now)
        end

        return result
	end

	def set_as_free_trial_plan
		p = Plan.find_by_name(free_trial_plan_name)
		if !p.nil?
			self.plan_id = p.id
			self.quantity = account.tire_stores.count
			self.contract_amount = p.plan_cost * self.quantity
			self.max_monthly_listings = p.default_num_listings
			self.billing_type = BillingTypes::AUTOMATED_CC_BILLING
			self.bill_cc = false
		end
	end

	def set_as_platinum_plan
		p = Plan.find_by_name(platinum_plan_name)
		if !p.nil?
			self.plan_id = p.id
			self.quantity = account.tire_stores.count
			self.contract_amount = p.plan_cost * self.quantity
			self.max_monthly_listings = p.default_num_listings
			self.billing_type = BillingTypes::AUTOMATED_CC_BILLING
			self.bill_cc = true
		end
	end

	def set_as_gold_plan
		p = Plan.find_by_name(gold_plan_name)
		if !p.nil?
			self.plan_id = p.id
			self.quantity = account.tire_stores.count
			self.contract_amount = p.plan_cost * self.quantity
			self.max_monthly_listings = p.default_num_listings
			self.billing_type = BillingTypes::AUTOMATED_CC_BILLING
			self.bill_cc = true
		else
			puts "*** COULD NOT FIND GOLD PLAN"
		end
	end

	def set_as_silver_plan
		p = Plan.find_by_name(silver_plan_name)
		if !p.nil?
			self.plan_id = p.id
			self.quantity = account.tire_stores.count
			self.contract_amount = p.plan_cost * self.quantity
			self.max_monthly_listings = p.default_num_listings
			self.billing_type = BillingTypes::NONE
			self.bill_cc = false
		end
	end

	# the special pricing plan is used to invoice at the given contract amount,
	# but is not tied to a subscription plan.  Therefore when we bill this one,
	# we will bill at the contract amount only.
	def set_as_special_pricing_plan
		self.quantity = 1
		self.max_monthly_listings = -1
		self.billing_type = BillingTypes::MANUAL_CC_BILLING
		self.bill_cc = true
	end

	def is_free_trial_plan?
		if !plan || plan.is_free_trial_plan?
			return true
		else
			return false
		end
	end

	def renew_contract
		if plan && plan.is_renewable?
			# create a new contract
			newContract = self.dup()
			newContract.start_date = self.expiration_date + 1.seconds
			newContract.save
		end
	end

	def can_have_filter_portal
		true
	end

	def can_have_search_portal
		true
	end

	def can_post_listings
		true
	end

	def can_use_branding
		true
	end

	def can_use_logo
		true
	end

	def can_use_mobile
		true
	end
end
