class DistributorImport < ActiveRecord::Base
	before_save :generate_uuid
	geocoded_by :real_address

	attr_accessible :uuid, :distributor_tier, :distributor_id, :warehouse_id
	attr_accessible :store_name, :store_address1, :store_address2
	attr_accessible :store_city, :store_state, :store_zipcode
	attr_accessible :store_phone
	attr_accessible :store_contact_first_name, :store_contact_last_name, :store_contact_email
	attr_accessible :latitude, :longitude
	attr_accessible :clicked, :clicked_at
	attr_accessible :registered, :registered_at

	serialize :other_information, ActiveRecord::Coders::Hstore

	attr_accessible :tire_store_id

	belongs_to :tire_store

	belongs_to :distributor
	belongs_to :warehouse

	def real_address
		"#{self.store_address1} #{self.store_address2}, #{self.store_city}, #{self.store_state} #{self.store_zipcode}"
	end

	def generate_uuid
		self.uuid = SecureRandom.uuid if self.uuid.blank?
	end

	def create_account_store_and_user
		@account = Account.new()
		@account.name = self.store_name
		@account.address1 = self.store_address1
		@account.address2 = self.store_address2
		@account.city = self.store_city
		@account.state = self.store_state
		@account.billing_email = self.store_contact_email
		@account.zipcode = self.store_zipcode
		@account.phone = number_to_phone(self.store_phone.gsub(/\D/, ''))

		@tire_store = TireStore.new
		@tire_store.name = self.store_name
		@tire_store.address1 = self.store_address1
		@tire_store.address2 = self.store_address2
		@tire_store.city = self.store_city
		@tire_store.state = self.store_state
		@tire_store.contact_email = self.store_contact_email
		@tire_store.zipcode = self.store_zipcode
		@tire_store.phone = number_to_phone(self.store_phone.gsub(/\D/, ''))

		@user = User.new
		@user.first_name = self.store_contact_first_name
		@user.last_name = self.store_contact_last_name
		@user.email = self.store_contact_email
		@user.zipcode = self.store_zipcode
		@user.phone = number_to_phone(self.store_phone.gsub(/\D/, ''))

		return @account, @tire_store, @user
	end

	def undo_registration
		if self.tire_store.nil? || !self.registered
			raise "This DistributorImport record has not been registered yet."
			return
		end

		@tire_store = self.tire_store

		# first delete the user
		users = @tire_store.account.users
		users.each do |u|
			if !u.is_super_user?
				u.destroy 
			end
		end

		# delete the account...that will delete the store and all its associations.
		acct = @tire_store.account
		acct.destroy

		# now "undo" the registration
		self.registered = false
		self.registered_at = nil
		self.tire_store_id = nil
		save
	end

	def self.create_test_records
		@tier_names = [["Tier 1", 10.0], ["Tier 2", 15.0], ["Tier 3", 20.0]]

		# first, create a test distributor record if it doesn't exist already
		@distributor = Distributor.find_or_initialize_by_distributor_name("TH Distributors")
		if @distributor.new_record?
			@distributor.address = "111 Main St"
			@distributor.city = "Atlanta"
			@distributor.state = "GA"
			@distributor.zipcode = "30092"
			@distributor.contact_name = "Kevin Irick"
			@distributor.contact_email = "kirick@treadhunter.com"
			@distributor.add_tire_manufacturer_id(TireManufacturer.find_by_name("Michelin").id)
			@distributor.add_tire_manufacturer_id(TireManufacturer.find_by_name("Goodyear").id)
			@distributor.add_tire_manufacturer_id(TireManufacturer.find_by_name("Dunlop").id)
			@distributor.add_tire_manufacturer_id(TireManufacturer.find_by_name("Cooper").id)
			@distributor.add_tire_manufacturer_id(TireManufacturer.find_by_name("Yokohama").id)
			@distributor.save
		end

		# now create a warehouse
		@warehouse = Warehouse.find_or_initialize_by_distributor_id_and_name(@distributor.id, "TH Distributors - Norcross")
		if @warehouse.new_record?
			@warehouse.address1 = "405 Oak St"
			@warehouse.city = "Norcross"
			@warehouse.state = "GA"
			@warehouse.zipcode = "30092"
			@warehouse.contact_email = "kirick@treadhunter.com"
			@warehouse.contact_name = "Kevin Irick"
			@warehouse.contact_phone = "7705551212"
			@warehouse.save
		end

		# create a "base price" pricing tier
		@base_tier = WarehouseTier.find_or_initialize_by_warehouse_id_and_tier_name(@warehouse.id, "base")
		if @base_tier.new_record?
			@base_tier.cost_pct_from_base = 0.0
			@base_tier.save 
		end

		# now create some pricing tiers
		@tier_names.each do |t|
			@tier = WarehouseTier.find_or_initialize_by_warehouse_id_and_tier_name(@warehouse.id, t[0])
			if @tier.new_record?
				puts "Setting cost basis for #{t[0]} to #{t[1]}"
				@tier.cost_pct_from_base = t[1]
				@tier.save
			end
		end

		# start a batch process to import prices from TCI as the base prices at 20% below
		# the TCI price.  Tier 1 is 10% above base, Tier 2 is 15% above base, and Tier 3 is 20% above base.
		@base_tier.delay.import_my_tier_pricing_from_tci(-20.0, true)

		100.times.each do |i|
			# get a random record from the scrape tire store table
			scrape_store = ScrapeTireStore.order("RANDOM()").first

			fake_name = Faker::Name.name
			ar_fake_name = fake_name.split(" ")
			while ar_fake_name.size != 2 
				fake_name = Faker::Name.name
				ar_fake_name = fake_name.split(" ")
			end

			di = DistributorImport.new
			di.distributor_tier = @tier_names[rand(@tier_names.size)][0]
			di.distributor_id = @distributor.id
			di.warehouse_id = @warehouse.id
			di.store_name = scrape_store.name
			di.store_address1 = scrape_store.address1
			di.store_address2 = scrape_store.address2
			di.store_city = scrape_store.city 
			di.store_state = scrape_store.state 
			di.store_zipcode = scrape_store.zipcode 
			di.store_phone = scrape_store.phone 
			di.store_contact_first_name = ar_fake_name[0]
			di.store_contact_last_name = ar_fake_name[1]
			di.store_contact_email = Faker::Internet.email
			di.clicked = false
			di.registered = false
			di.save
		end
	end
end