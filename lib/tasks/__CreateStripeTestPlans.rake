require 'stripe'

require "#{Rails.root}/app/helpers/application_helper"
include ApplicationHelper

def delete_stripe_plans(api_key)
    Stripe.api_key = api_key
    Stripe::Plan.all.each do |stripe_plan|
        stripe_plan.delete
    end
end

def create_stripe_plans(api_key)
    Stripe.api_key = api_key
    #Stripe::Plan.create(
    #        :amount => 15000,
    #        :interval => 'month',
    #        :name => 'Treadhunter Gold + Mobile',
    #        :currency => 'usd',
    #        :id => 'TH_GOLDMOBILE', 
    #        :trial_period_days => 30
    #        )
    Stripe::Plan.create(
            :amount => 14900,
            :interval => 'month',
            :name => platinum_plan_name,
            :currency => 'usd',
            :id => 'TH_PLATINUM', 
            :trial_period_days => (Date.parse((Time.now + free_trial_expiration).strftime('%Y/%m/%d')) - Date.parse((Time.now).strftime('%Y/%m/%d'))).to_i #free_trial_days
            )
    Stripe::Plan.create(
            :amount => 000,
            :interval => 'month',
            :name => free_trial_plan_name,
            :currency => 'usd',
            :id => 'TH_FREE', 
            :trial_period_days => 0
            )
    Stripe::Plan.create(
            :amount => 9900,
            :interval => 'month',
            :name => 'Treadhunter Gold',
            :currency => 'usd',
            :id => 'TH_GOLD', 
            :trial_period_days => (Date.parse((Time.now + free_trial_expiration).strftime('%Y/%m/%d')) - Date.parse((Time.now).strftime('%Y/%m/%d'))).to_i #30
            )
end

namespace :CreateStripePlans do
    desc "Create plans for Stripe"
    task populate: :environment do
        delete_stripe_plans(Rails.configuration.stripe[:secret_key])
        create_stripe_plans(Rails.configuration.stripe[:secret_key])
    end
end

namespace :CreatePlansFromStripe do
    desc "Create plans from list on Stripe"
    task populate: :environment do
        Stripe.api_key = Rails.configuration.stripe[:secret_key]

        Stripe::Plan.all.each do |stripe_plan|
            puts stripe_plan.id
            plan = Plan.find_by_stripe_plan(stripe_plan.id)
            if !plan
                plan = Plan.new
                plan.default_num_listings = -1
                plan.name = stripe_plan.name
                plan.stripe_plan = stripe_plan.id
                plan.save
            end
        end

        # create one for silver
        plan = Plan.new
        plan.default_num_listings = 0
        plan.name = silver_plan_name
        plan.stripe_plan = ""
        plan.save

        # create one for private sellers
        plan = Plan.new
        plan.default_num_listings = -1
        plan.name = special_pricing_plan_name
        plan.stripe_plan = ""
        plan.save

        # create one for special pricing - we will do single 
    end
end