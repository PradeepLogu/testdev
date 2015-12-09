class TireModel < ActiveRecord::Base
	attr_accessible :sidewall, :utqg_temp, :utqg_traction, :utqg_treadwear
	attr_accessible :load_index, :rim_width, :speed_rating, :tire_manufacturer_id
	attr_accessible :tire_size_id, :tread_depth, :name
	attr_accessible :orig_cost, :orig_currency
	attr_accessible :tire_category_id
	attr_accessible :product_code, :construction, :weight, :warranty_miles, :tire_code, :tire_model_info_id

  	attr_accessible :ply, :diameter, :revs_per_mile, :min_rim_width, :max_rim_width
  	attr_accessible :single_max_load_pounds, :dual_max_load_pounds, :single_max_psi, :dual_max_psi
  	attr_accessible :section_width, :weight_pounds, :active, :embedded_speed, :load_description
  	attr_accessible :tgp_category_id, :run_flat_id, :tgp_tire_type_id, :dual_load_index, :suffix

  	attr_accessible :tgp_model_id

	before_save :fix_tire_model_info

	belongs_to :tire_manufacturer
	belongs_to :tire_size

	has_many :tire_sizes
	has_many :tire_listings

	belongs_to :tire_model_info

	belongs_to :tire_category

	serialize :skus, ActiveRecord::Coders::Hstore

	composed_of :orig_cost,
		:class_name  => "Money",
		:mapping     => [%w(orig_cost cents), %w(orig_currency currency_as_string)],
		:constructor => Proc.new { |cents, orig_currency| Money.new(cents || 0, orig_currency || Money.default_currency) },
		:converter   => Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't conver #{value.class} to Money") }

	def realtime_quote_distributors
		return skus.keys
	end

	def tire_model_pricings
		@tire_model_pricings ||= TireModelPricing.find(:all, :conditions => ["tire_model_id = ?", self.id], :order => 'updated_at DESC')
	end

	def tci_price
		prices = tire_model_pricings().select{|tmp| tmp.source == "tcitips.com"}
		if prices.empty?
			return nil 
		else
			return prices.first.tire_ea_price
		end
	end

	def pepboys_price
		prices = tire_model_pricings().select{|tmp| tmp.source == "Pepboys.com"}
		if prices.empty?
			return nil 
		else
			return prices.first.tire_ea_price
		end
	end

	def walmart_price
		prices = tire_model_pricings().select{|tmp| tmp.source == "Walmart.com"}
		if prices.empty?
			return nil 
		else
			return prices.first.tire_ea_price
		end
	end

	def sears_price
		prices = tire_model_pricings().select{|tmp| tmp.source == "Sears.com"}
		if prices.empty?
			return nil 
		else
			return prices.first.tire_ea_price
		end
	end	

	def discount_tire_price
		prices = tire_model_pricings().select{|tmp| tmp.source == "DiscountTire.com"}
		if prices.empty?
			return nil 
		else
			return prices.first.tire_ea_price
		end
	end	

	def msrp_price
		prices = tire_model_pricings().select{|tmp| tmp.price_type == "msrp"}
		if prices.empty?
			return nil 
		else
			return prices.first.tire_ea_price
		end
	end

	def is_run_flat?
		return self.run_flat_id.to_i == 1
	rescue
		return false
	end

	def get_tgp_tire_type_description
		case self.tgp_tire_type.to_i
			when 1
				return "Passenger"
			when 2
				return "Light Truck/SUV"
			when 3
				return "Medium/Heavy Trucks"
			else
				return "Not defined"
		end
	rescue
		return "Not defined"
	end

	def translate_tgp_category_id(tgp_category_id)
		case tgp_category_id.to_i
			when 0
				return 0
			when 9
				return TireCategory.find_or_create_by_category_name("Winter").id
			when 11
				return TireCategory.find_or_create_by_category_name("On/Off Road").id
			when 12
				return TireCategory.find_or_create_by_category_name("Performance All-Season").id
			when 13
				return TireCategory.find_or_create_by_category_name("All Season").id
			when 14
				return TireCategory.find_or_create_by_category_name("High Performance Summer").id
			when 15
				return TireCategory.find_or_create_by_category_name("Summer").id
			when 16
				return TireCategory.find_or_create_by_category_name("Highway/Regional").id
			when 19
				return TireCategory.find_or_create_by_category_name("Touring Summer").id
			when 20
				return TireCategory.find_or_create_by_category_name("Standard Touring All-Season").id
			when 21
				return TireCategory.find_or_create_by_category_name("All Weather").id
			when 22
				return TireCategory.find_or_create_by_category_name("All Terrain").id
			when 23
				return TireCategory.find_or_create_by_category_name("Off Road").id
			when 24
				return TireCategory.find_or_create_by_category_name("Performance Touring All Season").id
			when 25
				return TireCategory.find_or_create_by_category_name("Performance Winter").id
			when 26
				return TireCategory.find_or_create_by_category_name("All Terrain Winter").id
			when 27
				return TireCategory.find_or_create_by_category_name("Mud Terrain").id
			else
				return 0
		end
	end

	def get_sku_for_tire_distributor_id(tire_distributor_id)
		self.skus = {} if self.skus == ""
		return self.skus[tire_distributor_id.to_s]
	end

	def set_sku_for_tire_distributor_id(tire_distributor_id, sku)
		self.skus = {} if self.skus == ""
		self.skus = (skus || {}).merge(tire_distributor_id.to_s => sku)
	end

	def remove_sku_for_tire_distributor_id(tire_distributor_id)
		self.skus = {} if self.skus == ""
		self.skus = self.skus.except(tire_distributor_id.to_s)
	end

	def formatted_orig_cost
		orig_cost.to_s
	end

	def name_and_product_code
		"#{self.name} (" + "#{self.load_index}#{self.speed_rating}" + (self.product_code.blank? ? '' : ' ' + self.product_code) + ")"
	end

	def self.search_by_tire_manufacturer_id_and_tire_size_id_and_name_and_product_code(manu_id, size_id, namestr)
		ar = namestr.scan(/(.*) \((\d{1,3})?(\D{1})? ?(.*)?\)/)
		if ar
			speed = ar[0][2]
			load = ar[0][1]
			product = ar[0][3]

			if speed.blank? && !product.blank?
				if product.length == 1
					speed = product
					product = ''
				end
			end

			speed = ['', ' ', nil] if speed.blank?
			load = nil if load.blank?
			product = ['', ' ', nil] if product.blank?

			TireModel.find_by_tire_manufacturer_id_and_tire_size_id_and_name_and_load_index_and_speed_rating_and_product_code(manu_id, size_id, ar[0][0], load, speed, product)
		end
	end

	def fix_tire_model_info
		if self.tire_model_info_id == -1
			tmi = TireModelInfo.find_by_tire_manufacturer_id_and_tire_model_name(self.tire_manufacturer_id, self.name)
			if !tmi
				tmi = TireModelInfo.new
				tmi.tire_manufacturer_id = self.tire_manufacturer_id
				tmi.tire_model_name = self.name
				tmi.save
			end

			self.tire_model_info_id = tmi.id 
		end
	end

        def self.tgp_categories
	  {
      9 => "Winter",
      11 => "On/Off Road",
      12 => "Performance All Season",
      13 => "All Season",
      14 => "Performance Summer",
      15 => "Summer",
      16 => "Highway/Regional",
      19 => "Touring Summer",
      20 => "Touring All Season",
      21 => "All Weather",
      22 => "All Terrain",
      23 => "Off Road",
      24 => "Performance Touring All Season",
      25 => "Performance Winter",
      26 => "All Terrain Winter",
      27 => "Mud Terrain"
	  }
	end
	
	#Returns a string or nil
	def get_tgp_category_name
	  TireModel.tgp_categories[self.tgp_category_id]
	end

	def description
		"#{self.tire_size.sizestr} #{self.tire_manufacturer.name} #{self.name} #{self.load_index}#{self.speed_rating}"
	end

	def has_recent_walmart_price_record
		tmp = TireModelPricing.find(:first, :conditions => ["tire_model_id = ? and price_type = 'retail' and source = 'Walmart.com' and updated_at >= ?", self.id, Time.now - 1.week])
		if tmp.nil?
			return false 
		else
			return true 
		end
	end

	def seems_to_match_walmart_product_description(walmart_desc)
		my_desc = self.description.downcase
		walmart_desc = walmart_desc.downcase

		bMatches = false 

		bMatches = walmart_desc.include?("#{self.load_index}#{self.speed_rating}".downcase)

		if bMatches
			bMatches = walmart_desc.include?("#{self.tire_size.sizestr}".downcase)
		end

		if bMatches
			bMatches = walmart_desc.include?("#{self.tire_manufacturer.name}".downcase)
		end

		if bMatches
			self.name.downcase.split(" ").each do |word|
				bMatches = bMatches & walmart_desc.include?(word)
			end
		end

		return bMatches
	end

	def starting_cost(locationstr)
		@listings = TireListing.near(locationstr).where("tire_model_id = ? and is_new = true", self.id).order("price ASC").limit(1)
		if @listings.size == 0
			return 0
		else
			return @listings.first.price
		end
	end

end
