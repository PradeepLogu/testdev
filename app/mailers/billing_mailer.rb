include TireStoresHelper

class BillingMailer < ActionMailer::Base
	default from: "TreadHunter Billing Dept. <mail@treadhunter.com>"

	def free_trial_expiring(account)
		@account = account
		@free_trial_contract = @account.current_contract
		if (!@free_trial_contract.nil? && @free_trial_contract.is_free_trial_plan? && 
			@account.tire_listings.count > 0 && @account.need_to_get_credit_card?) || true
			mail(:to => "cbkirick@gmail.com", #@account.billing_email,
		     	:subject => "Your TreadHunter Free Trial is Expiring!")
		end
	end

	def free_trial_expired(account)
		@account = account
		@free_trial_contract = @account.current_contract
		if (!@free_trial_contract.nil? &&
			!@free_trial_contract.is_free_trial_plan? &&
			@account.need_to_get_credit_card?) || true

			if @account.tire_listings.count > 0
				mail(:to => "cbkirick@gmail.com", #@account.billing_email,
		     		:subject => "Your TreadHunter Free Trial Has Expired!")
			else
				free_unused_trial_expired(account)
			end
		end
	end

	def free_unused_trial_expired(account)
		@account = account
		@free_trial_contract = @account.current_contract
		if (!@free_trial_contract.nil? &&
			!@free_trial_contract.is_free_trial_plan? &&
			@account.need_to_get_credit_card?) || true

			if @account.tire_listings.count == 0
				mail(:to => "cbkirick@gmail.com", #@account.billing_email,
		     		:subject => "Your TreadHunter Free Trial Has Expired!")
			else
				free_trial_expired(account)
			end
		end
	end

	def billing_problem(account)
		@account = account
		mail(:to => "cbkirick@gmail.com", #@account.billing_email,
	     	:subject => "We were unable to process your credit card")
	end


	#####################################################################
	def successfully_refunded_buyer(order, target_email, msg)
		@order = Order.find(order.id)

		@charge = Stripe::Charge.retrieve(@order.stripe_charge_token)

		@msg = msg

		if (@charge.refunds && @charge.refunds.total_count > 0) || Rails.env.development?
			puts "Sending email to #{target_email}"
			mail(:to => target_email,
     			:subject => "Your TreadHunter order has been refunded")
		else
			mail(:to => "bounce@treadhunter.com",
				:body => nil,
				:subject => "no subject")
		end
	end

	def successfully_refunded_seller(order, target_email, msg)
		@order = Order.find(order.id)
		@tire_store = @order.tire_store
		@tire_listing = @order.tire_listing

		@charge = Stripe::Charge.retrieve(@order.stripe_charge_token)

		@msg = msg

		if (@charge.refunds && @charge.refunds.total_count > 0) || Rails.env.development?
			mail(:to => target_email,
     			:subject => "TreadHunter order #{@order.id} has been refunded")
		else
			mail(:to => "bounce@treadhunter.com",
				:body => nil,
				:subject => "no subject")
		end
	end

	def successfully_billed_buyer(order, target_email)
		@order = Order.find(order.id)

		begin
			@stripe_customer = Stripe::Customer.retrieve(@order.stripe_buyer_customer_token)
			@card_last_4 = @stripe_customer.sources.first.last4 #@stripe_customer.active_card.last4
		rescue
			@stripe_customer = nil 
			@card_last_4 = ""
		end

		@appointment = @order.appointment
		@appt_link = "http://#{ActionMailer::Base.default_url_options[:host]}/appointments/new?order_id=#{@order.id}&order_uuid=#{@order.uuid}&tire_listing_id=#{@order.tire_listing_id}&tire_store_id=#{@order.tire_listing.tire_store_id}"

		if @order.has_sent_successful_charge_email == false || Rails.env.development?
			@order.has_sent_successful_charge_email = true 
			@order.save
			mail(:to => target_email,
     			:subject => "Your TreadHunter order has been successfully charged")
		else
			mail(:to => "bounce@treadhunter.com",
				:body => nil,
				:subject => "no subject")
		end
	end

	def successfully_billed_seller(order, target_email)
		# not currently being sent - 02/10/15 ksi
		@order = Order.find(order.id)
		@tire_store = @order.tire_store
		@tire_listing = @order.tire_listing

		@recipient = @tire_store.stripe_recipient_record
		if @recipient && @recipient.active_account
			if @recipient.active_account.object == "bank_account"
				@account_type = "bank account"
			else
				@account_type = "debit card"
			end
			@card_last_4 = @recipient.active_account.last4 
		else
			@account_type = "account on file"
			@card_last_4 = nil
		end

		@appointment = @order.appointment

		mail(:to => target_email,
     		:subject => "You have received a new order from TreadHunter.com")
	end

	def successfully_billed_buyer_text(order)
		@order = Order.find(order.id)
		begin
			@stripe_customer = Stripe::Customer.retrieve(order.stripe_buyer_customer_token)
			@card_last_4 = @stripe_customer.sources.first.last4 # @stripe_customer.active_card.last4
		rescue
			@stripe_customer = nil 
			@card_last_4 = ""
		end

		@appointment = @order.appointment
		@appt_link = "http://#{ActionMailer::Base.default_url_options[:host]}/appointments/new?order_id=#{@order.id}&order_uuid=#{@order.uuid}&tire_listing_id=#{@order.tire_listing_id}&tire_store_id=#{@order.tire_listing.tire_store_id}"

		mail(:to => "text@text.com",
     		:subject => "we don't use the subject for texts")
	end

	def successfully_billed_seller_text(order)
		@order = Order.find(order.id)		
		begin
			@stripe_customer = Stripe::Customer.retrieve(@order.stripe_buyer_customer_token)
			@card_last_4 = @stripe_customer.sources.first.last4 # @stripe_customer.active_card.last4
		rescue
			@stripe_customer = nil 
			@card_last_4 = ""
		end

		mail(:to => "text@text.com",
     		:subject => "subject is unimportant")
	end

	def failed_to_bill_buyer(order, msg)
		@order = Order.find(order.id)
		begin
			@stripe_customer = Stripe::Customer.retrieve(@order.stripe_buyer_customer_token)
			@card_last_4 = @stripe_customer.sources.first.last4 # @stripe_customer.active_card.last4
		rescue
			@stripe_customer = nil 
			@card_last_4 = ""
		end
		@msg = msg
		mail(:to => @order.buyer_email,
     		:subject => "TreadHunter - There was a problem billing your card")
	end

	def failed_to_bill_seller(order, msg)
		@order = Order.find(order.id)
		@msg = msg

		@tire_store = @order.tire_store

		mail(:to => @order.my_seller_email, 
     		:subject => "TreadHunter - New order with billing issue")
	end

	def successful_funds_transfer(order)
		@order = Order.find(order.id)

		@tire_store = @order.tire_store

		@recipient = @tire_store.stripe_recipient_record
		if @recipient && @recipient.active_account
			if @recipient.active_account.object == "bank_account"
				@account_type = "bank account"
			else
				@account_type = "debit card"
			end
			@card_last_4 = @recipient.active_account.last4 
		else
			@account_type = "account on file"
			@card_last_4 = nil
		end

		@appointment = @order.appointment
		@tire_listing = @order.tire_listing

		@confirm_appt_link = "http://#{ActionMailer::Base.default_url_options[:host]}/appointments/confirm?tire_store_id=#{@tire_store.id}"

		if @order.has_sent_funds_transfer_email == false
			@order.has_sent_funds_transfer_email = true 
			@order.save
			mail(:to => @order.my_seller_email, 
	     		:subject => "TreadHunter - Successful Money Transfer for Order #{@order.id}")
		else
			mail(:to => "bounce@treadhunter.com",
				:body => nil,
				:subject => "no subject")
		end
	end
end
