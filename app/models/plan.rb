require 'stripe'

class Plan < ActiveRecord::Base
  include ApplicationHelper

  attr_accessible :default_num_listings
  attr_accessible :name
  attr_accessible :stripe_plan

  def my_stripe_plan
  	@my_stripe_plan ||= get_stripe_plan()
  end

  def get_stripe_plan
    begin
      Stripe::Plan.retrieve(self.stripe_plan)
    rescue Exception => e 
      nil
    end
  end

  def plan_cost
    if my_stripe_plan.nil?
      Money.new(0, "usd")
    else
      Money.new(my_stripe_plan.amount, my_stripe_plan.currency)
    end
  end

  def plan_cost_formatted
  	"$" + Money.new(my_stripe_plan.amount, my_stripe_plan.currency).to_s if stripe_plan
  end

  def plan_trial_period
  	my_stripe_plan.trial_period_days if stripe_plan
  end

  def plan_interval
  	my_stripe_plan.interval if stripe_plan
  end

  def plan_name
  	my_stripe_plan.name if stripe_plan
  end

  def plan_cost_description
  	plan_cost_formatted + '/' + plan_interval if stripe_plan
  end

  def is_renewable?
    return !is_free_trial_plan?
  end

  def is_free_trial_plan?
    return (self.plan_name == free_trial_plan_name)
  end
end
