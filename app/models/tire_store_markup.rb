class TireStoreMarkup < ActiveRecord::Base
	attr_accessible :markup_dollars, :markup_pct, :markup_type, :tire_manufacturer_id
	attr_accessible :tire_model_id, :tire_model_info_id, :tire_size_id, :tire_store_id, :warehouse_id
	attr_accessible :tire_category_id

	# not db fields
	attr_accessible :skip, :markup_tire_category_id, :markup_tire_model_info_id, :markup_tire_size_id
	attr_accessor :skip, :markup_tire_category_id, :markup_tire_model_info_id, :markup_tire_size_id

	composed_of :markup_dollars,
		:class_name  => "Money",
		:mapping     => [%w(markup_dollars cents), %w(currency currency_as_string)],
		:constructor => Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
		:converter   => Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }

	after_initialize do |markup|
		markup.markup_tire_category_id = markup.markup_pct if markup.markup_tire_category_id.blank?
		markup.markup_tire_model_info_id = markup.markup_pct if markup.markup_tire_model_info_id.blank?
		markup.markup_tire_size_id = markup.markup_pct if markup.markup_tire_size_id.blank?
	end

	def markup_wholesale_price_as_money(raw_price)
		price = raw_price.to_money

		if markup_type == 0 # percentage
			return price + (price * (markup_pct / 100.00))
		elsif markup_type == 1 # fixed amount
			return price + markup_dollars
		else
			raise "Unknown markup type #{self.markup_type}"
		end
	end

	def manu_level_markup
		if self.tire_category_id.blank? &&
			self.tire_model_info_id.blank? &&
			self.tire_size_id.blank?
			return true 
		else
			return false
		end
	end
end
