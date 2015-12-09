class Promotion < ActiveRecord::Base
	attr_accessible :account_id, :description, :end_date, :promo_url, :promotion_type
	attr_accessible :start_date, :tire_manufacturer_id
	attr_accessible :tire_model_infos, :tire_store_ids, :tire_sizes
	attr_accessible :uuid, :promo_name, :promo_level, :promo_amount_min, :promo_amount_max
	attr_accessible :new_or_used

	has_attached_file :promo_attachment
	has_attached_file :promo_image, :styles => { :medium => "200x200>" }

	before_save :generate_uuid

	serialize :tire_store_ids, ActiveRecord::Coders::Hstore
	serialize :tire_model_infos, ActiveRecord::Coders::Hstore
	serialize :tire_sizes, ActiveRecord::Coders::Hstore
  
	validates :description, presence: true

	ALL_PROMO_TYPES = ['R', 'P', 'S', 'D', 'O']

	PROMO_LEVEL_CLAUSE = "(promo_level = 'N' or (promo_level = 'A' and account_id = ? and (tire_store_ids is null or tire_store_ids = '' or tire_store_ids @> hstore(?, 'tire_store_id'))))"
	PROMO_LEVEL_CLAUSE_STORE_ONLY = "(promo_level = 'A' and account_id = ? and (tire_store_ids @> hstore(?, 'tire_store_id')))"
	TIRE_MODELS_CLAUSE = "(tire_model_infos is null or tire_model_infos = '' or tire_model_infos @> hstore(?, 'tire_model_info_id'))"
	TIRE_SIZES_CLAUSE = "(tire_sizes is null or (tire_sizes @> hstore(?, 'tire_size_id')))"
	EXPIRE_CLAUSE = "(start_date <= current_date and end_date >= current_date)"
	scope "eligible_promotions", lambda { |tire_listing, promo_type| 
											if promo_type == "all"
												promo_type = ALL_PROMO_TYPES
											end
											if tire_listing.is_new? 
												new_or_used_clause = "(new_or_used = 'B' or new_or_used = 'N')"
											else
												new_or_used_clause = "(new_or_used = 'B' or new_or_used = 'U')"
											end
											where("promotion_type in (?) and #{new_or_used_clause} and #{PROMO_LEVEL_CLAUSE} and #{EXPIRE_CLAUSE}and (tire_manufacturer_id = ? and #{TIRE_MODELS_CLAUSE} and #{TIRE_SIZES_CLAUSE})",
														promo_type,
														(tire_listing.tire_store.nil? ? 0 : tire_listing.tire_store.account_id), tire_listing.tire_store_id.to_s, 
														tire_listing.tire_manufacturer_id, 
														tire_listing.tire_model_info_id, 
														tire_listing.tire_size_id.to_s)
										}
                    
	scope "store_promotions", lambda { |tire_store, promo_type| 
											if promo_type == "all"
												promo_type = ALL_PROMO_TYPES
											end
											where("promotion_type in (?) and #{PROMO_LEVEL_CLAUSE} and #{EXPIRE_CLAUSE}",
														promo_type,
                            tire_store.account_id, tire_store.id.to_s)
                  	}

	scope "store_only_promotions", lambda { |tire_store, promo_type| 
											if promo_type == "all"
												promo_type = ALL_PROMO_TYPES
											end
											where("promotion_type in (?) and #{PROMO_LEVEL_CLAUSE_STORE_ONLY} and #{EXPIRE_CLAUSE}",
														promo_type,
                            							tire_store.account_id, 
                            							tire_store.id.to_s)
                  	}

  	def self.local_and_national_promotions(location, radius, max_no)
  		# first we're going to try to find any local promos
  		ar = []
  		i = 0
  		while (ar.empty? && i <= 2)
  			ar = TireStore.near(location, radius, :select => 'id, account_id').where("private_seller = false")
  			i += 1
  		end

  		if !ar.empty?
  			ar_tire_store_ids = ar.map{|store| store.id}
  			ar_account_ids = ar.map{|store| store.account_id}.uniq.compact

			@local_promos = Promotion.find(:all, :conditions => ["id in (?)",
				ActiveRecord::Base.connection.execute(Promotion.local_promotions_only(ar_account_ids)).values.map{|r| r[0].to_i}])
		else
			@local_promos = []
		end

		# now find national promos
		@national_promos = Promotion.find(:all, :conditions => ["id in (?)",
				ActiveRecord::Base.connection.execute(Promotion.national_promotions_only).values.map{|r| r[0].to_i}])


		return (@local_promos.first(max_no) + @national_promos.first(max_no)).first(max_no), ar_tire_store_ids
  	end

  	def self.local_promotions(location, radius, max_no, promo_type="all")
  		# first we're going to try to find any local promos
  		ar = []
  		i = 0
  		while (ar.empty? && i <= 2)
  			ar = TireStore.near(location, radius, :select => 'id, account_id').where("private_seller = false")
  			i += 1
  		end

		if promo_type == "all"
			promo_type = ALL_PROMO_TYPES
		end

  		if !ar.empty?
  			ar_tire_store_ids = ar.map{|store| store.id}
  			ar_account_ids = ar.map{|store| store.account_id}.uniq.compact

  			promo_ids = ActiveRecord::Base.connection.execute(Promotion.local_promotions_only(ar_account_ids)).values.map{|r| r[0].to_i}

  			if promo_ids.empty?
  				@local_promos = []
  			else
				@local_promos = Promotion.find(:all, :conditions => ["id in (?) AND promotion_type in (?)",
					promo_ids, promo_type])
			end
		else
			@local_promos = []
		end

		return @local_promos.first(max_no)
  	end

  	def self.national_promotions 
		@national_promos = Promotion.find(:all, :conditions => ["id in (?)",
				ActiveRecord::Base.connection.execute(Promotion.national_promotions_only).values.map{|r| r[0].to_i}])
  	end

  	def self.local_promotions_only(ar_account_ids)
		"WITH summary AS ( " +
    	"   SELECT p.id, " + 
        "   p.uuid, " +
        "   ROW_NUMBER() OVER(PARTITION BY p.uuid " + 
        "                        ORDER BY p.id ASC) AS rk " +
      	" FROM PROMOTIONS p " +
      	" WHERE (start_date <= current_date and end_date >= current_date) " +
		" AND (promo_level = 'A' and account_id in (#{ar_account_ids.join(',')}))) " +
		" SELECT s.* " +
  		" FROM summary s " +
 		" WHERE s.rk = 1"
  	end

  	def self.national_promotions_only
		"WITH summary AS ( " +
    	"   SELECT p.id, " + 
        "   p.uuid, " +
        "   ROW_NUMBER() OVER(PARTITION BY p.uuid " + 
        "                        ORDER BY p.id ASC) AS rk " +
      	" FROM PROMOTIONS p " +
      	" WHERE (start_date <= current_date and end_date >= current_date) " +
		" AND (promo_level = 'N')) " +
		" SELECT s.* " +
  		" FROM summary s " +
 		" WHERE s.rk = 1"
  	end

  	def self.account_promotions_where_clause(ar_accounts, promo_type)
		if promo_type == "all"
			promo_type = ALL_PROMO_TYPES
		end
		"promotion_type in ('#{promo_type.join('\',\'')}') and (promo_level = 'A' and account_id in (#{ar_accounts}) and (start_date <= current_date and end_date >= current_date)"  		
	end
  
	def self.store_promotions_where_clause(tire_store, promo_type)
		if promo_type == "all"
			promo_type = ALL_PROMO_TYPES
		end
		"promotion_type in ('#{promo_type.join('\',\'')}') and (promo_level = 'N' or (promo_level = 'A' and account_id = #{(tire_store.account_id.blank? ? '0' : tire_store.account_id)} and (tire_store_ids is null or tire_store_ids = '' or tire_store_ids @> hstore('#{tire_store.id}', 'tire_store_id')))) and (start_date <= current_date and end_date >= current_date)"
	end

	def self.applicable_store_promotions_where_clause(tire_store, promo_type)
		if promo_type == "all"
			promo_type = ALL_PROMO_TYPES
		end
		"promotion_type in ('#{promo_type.join('\',\'')}') and (tire_manufacturer_id in (select distinct(tire_manufacturer_id) from tire_listings where tire_store_id = '#{tire_store.id}' and is_new = true)) and (promo_level = 'N' or (promo_level = 'A' and account_id = #{(tire_store.account_id.blank? ? '0' : tire_store.account_id)} and (tire_store_ids is null or tire_store_ids = '' or tire_store_ids @> hstore('#{tire_store.id}', 'tire_store_id')))) and (start_date <= current_date and end_date >= current_date) and true"
	end
  
	def self.non_national_store_promotions_where_clause(tire_store, promo_type)
		if promo_type == "all"
			promo_type = ALL_PROMO_TYPES
		end
		"promotion_type in ('#{promo_type.join('\',\'')}') and ((promo_level = 'A' and account_id = #{(tire_store.account_id.blank? ? '0' : tire_store.account_id)} and (tire_store_ids is null or tire_store_ids = '' or tire_store_ids @> hstore('#{tire_store.id}', 'tire_store_id')))) and (start_date <= current_date and end_date >= current_date)"
	end  
  
	def self.store_promotions_select_unique(tire_store, promo_type)
		"WITH summary AS ( " +
		"    SELECT p.id, " +
		"           p.uuid, " +
		"           ROW_NUMBER() OVER(PARTITION BY p.uuid " +
		"                                 ORDER BY p.id ASC) AS rk " +
		"      FROM PROMOTIONS p " +
		"      WHERE #{Promotion.store_promotions_where_clause(tire_store, promo_type)}) " +
		"SELECT s.* " +
		"  FROM summary s " + 
		" WHERE s.rk = 1"
	end
  
	def self.store_promotions_select_unique_applicable(tire_store, promo_type)
		"WITH summary AS ( " +
		"    SELECT p.id, " +
		"           p.uuid, " +
		"           ROW_NUMBER() OVER(PARTITION BY p.uuid " +
		"                                 ORDER BY p.id ASC) AS rk " +
		"      FROM PROMOTIONS p " +
		"      WHERE #{Promotion.applicable_store_promotions_where_clause(tire_store, promo_type)}) " +
		"SELECT s.* " +
		"  FROM summary s " + 
		" WHERE s.rk = 1"
	end
  
	def self.non_national_store_promotions_select_unique(tire_store, promo_type)
		"WITH summary AS ( " +
		"    SELECT p.id, " +
		"           p.uuid, " +
		"           ROW_NUMBER() OVER(PARTITION BY p.uuid " +
		"                                 ORDER BY p.id ASC) AS rk " +
		"      FROM PROMOTIONS p " +
		"      WHERE #{Promotion.non_national_store_promotions_where_clause(tire_store, promo_type)}) " +
		"SELECT s.* " +
		"  FROM summary s " + 
		" WHERE s.rk = 1"
	end
  
	def self.unique_store_promotions(tire_store, promo_type)
		if promo_type == "all"
			promo_type = ALL_PROMO_TYPES
		end
		Promotion.find(:all, :conditions => ["id in (?)",
			ActiveRecord::Base.connection.execute(Promotion.store_promotions_select_unique(tire_store, "all")).values.map{|r| r[0].to_i}])
	end
  
	def self.unique_applicable_store_promotions(tire_store, promo_type)
		if promo_type == "all"
			promo_type = ALL_PROMO_TYPES
		end
		Promotion.find(:all, :conditions => ["id in (?)",
			ActiveRecord::Base.connection.execute(Promotion.store_promotions_select_unique_applicable(tire_store, "all")).values.map{|r| r[0].to_i}])
	end
  
	def self.unique_non_national_store_promotions(tire_store, promo_type)
		if promo_type == "all"
			promo_type = ALL_PROMO_TYPES
		end
    	Promotion.find(:all, :conditions => ["id in (?)",
      		ActiveRecord::Base.connection.execute(Promotion.non_national_store_promotions_select_unique(tire_store, "all")).values.map{|r| r[0].to_i}])
	end
  
	def self.geo_promotions(latitude, longitude, radius, promo_type)
		if promo_type == "all"
			promo_type = ALL_PROMO_TYPES
		end

		# first find all the stores in the region    
		@tire_stores = TireStore.near([latitude, longitude], radius).find(:all)
		@tire_stores_accounts = TireStore.near([latitude, longitude], radius).find(:all).map{|t| t.account_id}.uniq

		if @tire_stores.count > 0
			@tire_stores_clause = "(promo_level = 'N' or (" + @tire_stores.map{|x| "tire_store_ids @> hstore('#{x.id}', 'tire_store_id')"}.join(' or ') + "))"
		else
			@tire_stores_clause = "(promo_level = 'N')"
		end
		if @tire_stores_accounts.count > 0
			@tire_stores_clause += " or (promo_level = 'A' and (account_id in (#{@tire_stores_accounts.join(',')})))"
		end

		# now find the promotions that fit our criteria
		Promotion.find(:all, :conditions => ["promotion_type in (?) and #{EXPIRE_CLAUSE} and #{@tire_stores_clause}", promo_type])
	end

	def promotion_level_text
		if promo_level == "N"
			"National"
		elsif promo_level == "A"
			"Account"
		else
			"Undefined"
		end
	end
  
	def full_description
		result = ""
		@full_promos = Promotion.find_all_by_uuid(self.uuid, :order => :id)

		@master_promotion = @full_promos.first

		if !@master_promotion.nil?
			if @master_promotion.promotion_type == 'R'
				result += "<h2>Rebate Offer</h2>"
			elsif @master_promotion.promotion_type == 'D' && !@master_promotion.dollar_amount.nil? && !@master_promotion.dollar_amount.blank?
				result += "<h2>Special price - #{@master_promotion.dollar_amount} off</h2>"
				result += "<h2>Eligible Tires:</h2>"
			elsif @master_promotion.promotion_type == 'P'
				result += "<h2>#{@master_promotion.promo_amount_min}% off all eligible tires"
			elsif @master_promotion.promotion_type == 'S'
				result += "<h2>Special Offer</h2>"
			elsif @master_promotion.promotion_type == 'O'
				result += "<h2>Other Special Offer</h2>"
			end

			result += @master_promotion.description.html_safe

			@full_promos.each do |single_promotion|
				if !single_promotion.tire_model_infos.blank?
					result += "<div><p><u>#{single_promotion.dollar_amount}</u></p></div>"
					single_promotion.tire_model_infos_list.each do |m|
						result += "<p>#{m.tire_manufacturer.name} #{m.tire_model_name}</p>"
					end
				end
			end
		end
		return result
	end

	def summary
		@full_promos = Promotion.find_all_by_uuid(self.uuid, :order => :id)

		@master_promotion = @full_promos.first

		if !@master_promotion.nil?
			if @master_promotion.promotion_type == 'R'
				if @master_promotion.dollar_amount.blank?
					result = "Rebate Offer"
				else
					result = "Rebate Offer (#{@master_promotion.dollar_amount})"
				end
			elsif @master_promotion.promotion_type == 'D' && !@master_promotion.dollar_amount.nil? && !@master_promotion.dollar_amount.blank?
				result = "Special price - #{@master_promotion.dollar_amount} off"
			elsif @master_promotion.promotion_type == 'P'
				result = "#{@master_promotion.promo_amount_min}% off all eligible tires"
			elsif @master_promotion.promotion_type == 'S'
				result = "Special Offer"
			elsif @master_promotion.promotion_type == 'O'
				result = "Other Offer"
			end
		else
			result = ""
		end
		return result
	end

	def remaining_time
		result = ""
		@days_remaining = self.end_date.mjd - Date.today.mjd
		if @days_remaining >= 0 && @days_remaining <= 7
			result = "Limited Time: "
		else
			result = "Valid Dates: "
		end
		result += self.start_date.to_formatted_s(:long) + " - " + self.end_date.to_formatted_s(:long)
	end

	def text_description
		result = ""
		@full_promos = Promotion.find_all_by_uuid(self.uuid, :order => :id)

		@master_promotion = @full_promos.first

		if !@master_promotion.nil?
			result += self.summary + " - "

			result += @master_promotion.description.html_safe

			manufacturers = @full_promos.map{|m| m.tire_model_infos_list.map{|l| l.tire_manufacturer.name}.flatten}.flatten.to_a.uniq.join(",")

			if !manufacturers.blank?
				result += " (#{manufacturers})"
			end
		end
		return result
	end	
  
	def add_tire_store_id_to_promotion(tire_store_id)
		self.tire_store_ids = {} if self.tire_store_ids == ""
		self.tire_store_ids = (tire_store_ids || {}).merge(tire_store_id.to_s => "tire_store_id")
	end

	def remove_tire_store_id_from_promotion(tire_store_id)
		self.tire_store_ids = {} if self.tire_store_ids == ""
		self.tire_store_ids = self.tire_store_ids.except(tire_store_id.to_s)
	end

	def add_tire_model_info_id_to_promotion(tire_model_info_id)
		self.tire_model_infos = {} if self.tire_model_infos == ""
		self.tire_model_infos = (tire_model_infos || {}).merge(tire_model_info_id.to_s => "tire_model_info_id")
	end

	def remove_tire_model_info_id_from_promotion(tire_model_info_id)
		self.tire_model_infos = {} if self.tire_model_infos == ""
		self.tire_model_infos = self.tire_model_infos.except(tire_model_info_id.to_s)
	end

	def generate_uuid
		self.uuid = SecureRandom.uuid if self.uuid.nil? || self.uuid.size == 0
	end

	def dollar_amount
		if promo_amount_min.nil? && promo_amount_max.nil?
			""
		elsif promo_amount_min.nil?
			"$#{promo_amount_max.to_money.to_s}"
		elsif promo_amount_max.nil?
			"$#{promo_amount_min.to_money.to_s}"
		elsif promo_amount_min.to_money.to_s == promo_amount_max.to_money.to_s
			"#{promo_amount_min.to_money.to_s}"
		else
			"From $#{promo_amount_min.to_money.to_s} to $#{promo_amount_max.to_money.to_s}"
		end
	end

	def tire_model_infos_list
		result = []
		self.tire_model_infos.keys.each do |k|
			if self.tire_model_infos[k] == "tire_model_info_id"
				tmi = TireModelInfo.find_by_id(k)
				result << TireModelInfo.find(k) unless tmi.nil?
			end
		end
		result
	end
  
	def promo_image_url
		if !self.promo_image_file_name.blank?
			self.promo_image.url 
		elsif self.promo_level == "N"
			"/assets/TH_Deal_02.jpg"
		else
			"/assets/TH_Deal_01.jpg"
		end
	end

	def promo_attachment_url
		self.promo_attachment.url if !self.promo_attachment_file_name.blank?
	end

	def has_tirelistings_for_promo?(tire_store)
		!TireListing.includes(:tire_model).where("tire_listings.tire_store_id = ? and tire_models.tire_model_info_id in (?)", tire_store.id, tire_model_infos.keys).first.nil?
	end

	def apply(start_price)
		if self.promotion_type == "D"
			# discount amount - flat
			start_price - self.promo_amount_min
		elsif self.promotion_type == "R"
			# rebate - do not apply anything
			start_price
		elsif self.promotion_type == "P"
			# percentage
			((100 - self.promo_amount_min) * start_price) / 100
		elsif self.promotion_type == "S"
			# special price
			self.promo_amount_min
		elsif self.promotion_type == "O"
			# other - do not apply anything
			start_price
		end
	end

	def nearest_tire_store(location, radius)
		@nearest_tire_store ||= begin
			location = "Atlanta, GA" if location.blank?

			if self.promo_level == "A"
				@tire_stores = TireStore.near(location, radius).where("account_id = ?", self.account_id)
			else
				@tire_stores = TireStore.near(location, radius).where("private_seller = false")
			end

			if @tire_stores.empty?
				nil 
			else
				@tire_stores.first
			end
		end
	end

	def valid_for_store?(tire_store)
		return false if !tire_store

		if self.promo_level == "N"
			return true# TODO - fix this - tire_store.can_offer_national_promotion?(self)
		elsif self.promo_level == "A"
			if self.account_id == tire_store.account_id
				if self.tire_store_ids.nil? || self.tire_store_ids.size == 0 ||
					self.tire_store_ids[tire_store.id.to_s] == "tire_store_id"
					return true
				else
					return false
				end
			else
				return false
			end
		else
			return false
		end
	end
end
