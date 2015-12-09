
namespace :TestCreditCard do
    desc "Test credit card processing"
    task test: :environment do
		a = Account.first
		puts "Stripe ID => #{a.stripe_id}"
		if a.need_to_get_credit_card
			puts "Need to get a credit card"
			Stripe.api_key = stripe_public_key
			@customer = Stripe::Customer.retrieve(a.stripe_id)
			#@customer.cards.create(:card => "tok_16wPK0phhlIycW")
			@customer.cards.create(:card => {
												:number => "4242424242424242",
												:type => "Visa",
												:exp_month => 8,
												:exp_year => 2014,
												:cvc => "111",
												:name => "Fred Flintstone"
											})
		else
			puts "No need to get a card"
		end
		c = a.create_special_billing_contract(4000, Time.now, Time.now + 30.days)
	end
end