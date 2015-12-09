class ChargesController < ApplicationController
	def create
	  # Amount in cents
	  @amount = 0

	  #@customer = Stripe::Customer.create(
	  #  :email => current_user.account.billing_email,
	  #  :card  => params[:stripeToken],
	  #  :plan => 'TH_PLATINUM'
	  #)

	  #puts "#{@customer}"
	  #puts "#{charge}"

	  current_user.account.update_attribute(:stripe_id, @customer.id)

	rescue Stripe::CardError => e
	  flash[:error] = e.message
	  redirect_to charges_path
	  return
	end

	def cc_entered
		if params[:stripeToken].nil?
			redirect_to '/', :alert => 'You have reached this page in error.'
			return
		end

		if current_user.nil?
			redirect_to '/', :alert => 'You have reached this page in error.  Log in and try again.'
			return
		end

		@account = current_user.account

		if @account.nil?
			redirect_to '/', :alert => 'You must create or select an account.'
			return
		end

		if !@account.validate_stripe_id
			# We'll give him a new ID
			@customer = Stripe::Customer.create(
				:email => @account.billing_email,
				:card  => params[:stripeToken]
			)
		else
			@customer = Stripe::Customer.retrieve(@account.stripe_id)
			@customer.card = params[:stripeToken]
			@customer.save
		end

		redirect_to '/myTreadHunter', :alert => 'Credit card updated successfully.'
    rescue Exception => e
    	flash[:error] = e.message
		redirect_to :action => :cc_info, :controller => :pages, :protocol => (Rails.env.production? ? 'https://' : 'http://')
		return
	end
end
