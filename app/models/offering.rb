class Offering
	# sort order, attribute name (should not change), 
	# description that might chg, default value
	ALL_STORE_OFFERINGS = [
								[1, :has_overnight,     "Overnight Drop-off", false],
								[2, :has_wifi,          "Wi-Fi in Waiting Room", false],
								[3, :has_shuttle,       "Offers Shuttle or Vehicle Pickup", false],
								[4, :has_six_month,     "6 Months No Interest", false],
								[5, :has_twelve_month,  "Overnight Drop-off", false],
								[6, :has_air,           "Check and fill tire air pressure with any service", true],
								[7, :has_ase_cert,      "ASE-certified technicians", true],
								[8, :has_coffee,        "Free Coffee in Waiting Room", false]
							]

	ALL_SERVICE_OFFERINGS = [
	                            [1,  :has_svc_air_conditioning,    "Air Conditioning", true],
	                            [2,  :has_svc_batteries,           "Batteries", true],
	                            [3,  :has_svc_belts_hoses,         "Belts & Hoses", true],
	                            [4,  :has_svc_brake_systems,       "Brake Systems Repair", true],
	                            [5,  :has_svc_electrical_systems,  "Electrical Systems", true],
	                            [6,  :has_svc_engine_diag,         "Engine Diagnostics", true],
	                            [7,  :has_svc_headlamps,           "Headlamps & Bulbs", true],
	                            [8,  :has_svc_heating_cooling,     "Heating & Coolant Systems", true],
	                            [9,  :has_svc_mufflers,            "Mufflers & Exhaust", true],
	                            [10, :has_svc_oil_lube,            "Oil, Lube & Filter Services", true],
	                            [11, :has_svc_maintenance,         "Preventative Maintenance", true],
	                            [12, :has_svc_packages,            "Packages", true],
	                            [13, :has_svc_shocks,              "Shocks & Struts", true],
	                            [14, :has_svc_starting_systems,    "Starting & Charging Systems", true],
	                            [15, :has_svc_steering_suspension, "Steering & Suspension Systems", true],
	                            [16, :has_svc_timing_belts,        "Timing Belts", true],
	                            [17, :has_svc_tire_install,        "Tire Installation", true],
	                            [18, :has_svc_tire_pressure,       "Tire Pressure Monitoring", true],
	                            [19, :has_svc_systems,             "Systems", true],
	                            [20, :has_svc_tire_repair,         "Tire Repair", true],
	                            [21, :has_svc_tire_rotation,       "Tire Rotation", true],
	                            [22, :has_svc_tune_ups,            "Tune Ups", true],
	                            [23, :has_svc_wheel_alignment,     "Wheel Alignment", true],
	                            [24, :has_svc_wheel_balancing,     "Wheel and Tire Balancing", true],
	                            [25, :has_svc_wipers,              "Wiper Blades", true]
							]							
							
	def self.store_offering_attributes
		return ALL_STORE_OFFERINGS.sort.map(&:second)
	end

	def self.store_services_attributes
		return ALL_SERVICE_OFFERINGS.sort.map(&:second)
	end

	def self.store_offering_attributes_and_description
		return ALL_STORE_OFFERINGS.sort.map{|ar| [ar[1], ar[2]]}
	end

	def self.store_services_attributes_and_description
		return ALL_SERVICE_OFFERINGS.sort.map{|ar| [ar[1], ar[2]]}
	end

	def self.store_offerings(tire_store)
		result = []
		Offering.store_offering_attributes_and_description.each do |att, desc|
			if tire_store.respond_to?(att)
				result << [att, tire_store.send(att), desc]
			end
		end
		result
	end

	def self.store_services(tire_store)
		result = []
		Offering.store_services_attributes_and_description.each do |att, desc|
			if tire_store.respond_to?(att)
				result << [att, tire_store.send(att), desc]
			end
		end
		result
	end

	def self.is_valid_store_offering_property(prop_name)
		return !ALL_STORE_OFFERINGS.map{|ar| [ar[1].to_s]}.select{|a| a.first == prop_name.to_s}.empty?
	end

	def self.get_default_store_offering_value(attr_name)
		x = ALL_STORE_OFFERINGS.map{|ar| [ar[1].to_s, ar[3]]}.select{|a| a.first == attr_name.to_s}[0]
		if x 
			return x.last
		else
			return false
		end
	end

	def self.is_valid_service_offering_property(prop_name)
		return !ALL_SERVICE_OFFERINGS.map{|ar| [ar[1].to_s]}.select{|a| a.first == prop_name.to_s}.empty?
	end

	def self.get_default_service_offering_value(attr_name)
		x = ALL_SERVICE_OFFERINGS.map{|ar| [ar[1].to_s, ar[3]]}.select{|a| a.first == attr_name.to_s}[0]
		if x 
			return x.last
		else
			return false
		end
	end
end