namespace :InitializeContracts do
    desc "Create contract data for accounts"
    task bogus: :environment do
        clean()
        ##create_contracts(true, nil)
    end

    task :real, [:free_trial_expiration] => :environment do |t, args|
        exp_date = args[:free_trial_expiration]
        exp_date = Time.now + 60.days if exp_date.nil? || exp_date == ""
        clean()
        ##create_contracts(false, exp_date)
    end
end

def clean()
    clean_stripe_invoices
    clean_stripe_customer_data
    clean_stripe_account_data
    delete_all_contracts
end

def clean_stripe_invoices
    #Stripe::Invoice.all.each do |i|
    #    i.delete
    #end
end

def clean_stripe_customer_data
    while (Stripe::Customer.all.count > 0) do
        Stripe::Customer.all(:count => 100).each do |c|
            puts "Deleting #{c.id}"
            c.delete
        end
    end
end

def clean_stripe_account_data
    Account.all.each do |a|
        a.stripe_id = ""
        a.save
    end
end

def delete_all_contracts
    Contract.all.each do |c|
        c.delete
    end
end

def create_contracts(randomize, exp_date)
    Account.find(:all, :limit => 20).each do |a|
        a.register_with_stripe()

        if randomize
            a.create_free_trial_contract(Time.now - 55.days - rand(5).days, 60)
            a.create_platinum_contract
        else
            a.create_free_trial_contract()
            a.create_platinum_contract
        end
    end
end