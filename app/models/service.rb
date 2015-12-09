class Service < ActiveRecord::Base  
	attr_accessible :service_name

	def self.seed_data
	    # Create the seed data
	    ["Air Filters","Batteries","Belts and Hoses",
	    	"Brakes","Cooling System Maintenance","Drive Lines",
	    	"Electrical Systems","Engine Diagnostics and Repair",
	    	"Exhaust","Fluids","Headlight Restoration","Heating and A/C",
	    	"Nitrogen","Oil Change Service","Preventative Maintenance",
	    	"Steering and Suspension","Tire Balancing","Tire Installation",
	    	"Tire Repair","Tire Rotation","Transmission Fluid Flush",
	    	"Wheel Alignment","Wiper Blades"].each do |svc|
  			Service.find_or_create_by_service_name svc
	    end
    end
end