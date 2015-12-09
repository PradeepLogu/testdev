class GenericTireListing < ActiveRecord::Base
	attr_accessible :currency, :includes_mounting, :mounting_price, :price, :quantity
	attr_accessible :remaining_tread_max, :remaining_tread_min, :tire_sizes, :tire_store_id
	attr_accessible :treadlife_max, :treadlife_min, :warranty_days

	validates_presence_of :tire_store_id

	has_many :tire_listings

	belongs_to :tire_store

	after_save :update_tire_listings
	before_destroy :delete_all_listings

	serialize :tire_sizes, ActiveRecord::Coders::Hstore

	composed_of :price,
		:class_name  => "Money",
		:mapping     => [%w(price cents), %w(currency currency_as_string)],
		:constructor => Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
		:converter   => Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }

	composed_of :mounting_price,
		:class_name  => "Money",
		:mapping     => [%w(mounting_price cents), %w(currency currency_as_string)],
		:constructor => Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
		:converter   => Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }

	def add_tire_size_id(tire_size_id)
		self.tire_sizes = {} if self.tire_sizes == ""
		self.tire_sizes = (tire_sizes || {}).merge(tire_size_id.to_s => "tire_size_id")
	end

	def remove_tire_size_id(tire_size_id)
		self.tire_sizes = {} if self.tire_sizes == ""
		self.tire_sizes = self.tire_sizes.except(tire_size_id.to_s)
	end

	def populate_with_test_values
		self.tire_store_id = 33075 # TireStore.last.id
		self.add_tire_size_id(TireSize.find_by_sizestr('215/65R16').id)
		self.add_tire_size_id(TireSize.find_by_sizestr('215/70R16').id)
		self.add_tire_size_id(TireSize.find_by_sizestr('225/70R16').id)
		self.add_tire_size_id(TireSize.find_by_sizestr('235/65R16').id)
		self.add_tire_size_id(TireSize.last.id)
		self.includes_mounting = true
		#self.mounting_price = 10
		self.price = 29.99
		self.quantity = 99
		self.remaining_tread_min = 4
		self.remaining_tread_max = 10
		#self.treadlife_min = 40
		#self.treadlife_max = 85
		self.warranty_days = 0
	end

	private
		def update_tire_listings
			# now go through each size.  If we have an existing listing, update it.  If not,
			# create it.
			tire_sizes.keys.each do |tire_size_id|
				t = TireListing.find_by_generic_tire_listing_id_and_tire_size_id(self.id, tire_size_id)
				if t.nil?
					t = TireListing.new
					t.generic_tire_listing_id = self.id
					t.is_generic = true
					t.tire_store_id = self.tire_store_id
					t.tire_size_id = tire_size_id
				end

				if self.quantity && self.quantity < 4 && self.quantity > 0
					t.quantity = self.quantity
				else
					t.quantity = 4
				end

				t.tire_manufacturer_id = -1
				t.tire_model_id = -1
				t.treadlife = self.treadlife_min
				t.remaining_tread = self.remaining_tread_min

				t.sell_as_set_only = false
				t.price = self.price
				t.warranty_days = self.warranty_days
				t.includes_mounting = self.includes_mounting

				t.save
			end

			delete_unattached_tire_listings()
		end

		def delete_unattached_tire_listings
			tire_listings.each do |t|
				if !tire_sizes.include?(t.tire_size_id.to_s)
					t.delete
				end
			end
		end

		def delete_all_listings
			tire_listings.each do |t|
				t.destroy
			end
		end
end
