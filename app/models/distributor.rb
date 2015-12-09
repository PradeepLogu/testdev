class Distributor < ActiveRecord::Base
	attr_accessible :address, :city, :contact_email, :contact_name, :distributor_name
	attr_accessible :state, :zipcode, :tire_manufacturers

	serialize :tire_manufacturers, ActiveRecord::Coders::Hstore

	has_many :tire_store_distributors

	def self.tci_distributor_name
		return "Tire Centers, LLC"
	end

	def ready_for_scrape
		TireStoresDistributor.where("distributor_id = ? and next_run_time <= ? and frequency_days > 0", self.id, Time.now)
	end

  	def add_tire_manufacturer_id(tire_manufacturer_id)
		self.tire_manufacturers = {} if self.tire_manufacturers == ""
		self.tire_manufacturers = (tire_manufacturers || {}).merge(tire_manufacturer_id.to_s => "tire_manufacturer_id")
	end

	def remove_tire_manufacturer_id(tire_manufacturer_id)
		self.tire_manufacturers = {} if self.tire_manufacturers == ""
		self.tire_manufacturers = self.tire_manufacturers.except(tire_manufacturer_id.to_s)
	end

	def tire_manufacturers_list
		result = []
		self.tire_manufacturers.keys.each do |k|
			if self.tire_manufacturers[k] == "tire_manufacturer_id"
				result << TireManufacturer.find(k)
			end
		end
		result
	end	
end
