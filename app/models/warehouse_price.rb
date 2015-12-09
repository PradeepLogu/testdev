class WarehousePrice < ActiveRecord::Base
	attr_accessible :base_price, :base_price_warehouse_price_id, :cost_pct_from_base
	attr_accessible :tire_model_id, :warehouse_id, :warehouse_tier_id, :wholesale_price

	belongs_to :tire_model 
	has_one :tire_manufacturer, :through => :tire_model
	has_one :tire_size, :through => :tire_model
	has_one :tire_model_info, :through => :tire_model 

	composed_of :wholesale_price,
		:class_name  => "Money",
		:mapping     => [%w(wholesale_price cents), %w(currency currency_as_string)],
		:constructor => Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
		:converter   => Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }

	composed_of :base_price,
		:class_name  => "Money",
		:mapping     => [%w(base_price cents), %w(currency currency_as_string)],
		:constructor => Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
		:converter   => Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }

end
