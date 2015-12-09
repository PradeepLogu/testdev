class TireModelPricing < ActiveRecord::Base
	attr_accessible :tire_model_id
	attr_accessible :source # eg eBay, CheckAFlip, TCI API, Goodyear, etc.
	attr_accessible :orig_source # eBay, TCI API, Goodyear, etc.
	attr_accessible :source_url
	attr_accessible :price_type # eg retail, wholesale, msrp
	attr_accessible :tire_ea_price
	attr_accessible :other_properties
	attr_accessible :zipcode

	composed_of :tire_ea_price,
		:class_name  => "Money",
		:mapping     => [%w(tire_ea_price cents), %w(orig_currency currency_as_string)],
		:constructor => Proc.new { |cents, orig_currency| Money.new(cents || 0, orig_currency || Money.default_currency) },
		:converter   => Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't conver #{value.class} to Money") }
	
end
