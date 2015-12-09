class InstallationCost < ActiveRecord::Base
	attr_accessible :account_id, :ea_install_price
	attr_accessible :max_wheel_diameter, :min_wheel_diameter
	attr_accessible :other_properties, :tire_store_id

	serialize :other_properties, ActiveRecord::Coders::Hstore

	RUNFLAT_SIZE = 0
	TPMS_SIZE = -1

	composed_of :ea_install_price,
		:class_name  => "Money",
		:mapping     => [%w(ea_install_price cents), %w(currency currency_as_string)],
		:constructor => Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
		:converter   => Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }

	def self.create_default_installation_costs
		current_install_price = 15.00

		(13..25).each do |i|
			current_cost = InstallationCost.find(:all, :conditions => ["account_id = 0 and min_wheel_diameter = ? and max_wheel_diameter = ?", i, i])
			if current_cost.nil? || current_cost.size == 0
				ic = InstallationCost.new
				ic.account_id = 0
				ic.ea_install_price = current_install_price
				ic.parts_portion = 7
				ic.max_wheel_diameter = i
				ic.min_wheel_diameter = i
				ic.tire_store_id = 0
				ic.save
			end
			current_install_price += 1.0
		end

		# now create one for run_flat
		ic = InstallationCost.new
		ic.account_id = 0
		ic.ea_install_price = 21.95
		ic.parts_portion = 7
		ic.max_wheel_diameter = RUNFLAT_SIZE
		ic.min_wheel_diameter = RUNFLAT_SIZE
		ic.tire_store_id = 0
		ic.save

		# now create one for TPMS
		ic = InstallationCost.new
		ic.account_id = 0
		ic.ea_install_price = 5
		ic.parts_portion = 5
		ic.max_wheel_diameter = TPMS_SIZE
		ic.min_wheel_diameter = TPMS_SIZE
		ic.tire_store_id = 0
		ic.save
	end

	def self.get_installation_record(account_id, tire_store_id, wheel_diameter, run_flat=false)
		if run_flat
			wheel_diameter = RUNFLAT_SIZE
		end

		all_applicable_install_costs = InstallationCost.find(:all, :conditions => ["tire_store_id = ? and min_wheel_diameter <= ? and max_wheel_diameter >= ?", tire_store_id, wheel_diameter, wheel_diameter], :order => 'ea_install_price desc')
		if all_applicable_install_costs.nil? || all_applicable_install_costs.size == 0
			all_applicable_install_costs = InstallationCost.find(:all, :conditions => ["account_id = ? and min_wheel_diameter <= ? and max_wheel_diameter >= ?", account_id, wheel_diameter, wheel_diameter], :order => 'ea_install_price desc')
		end
		if all_applicable_install_costs.nil? || all_applicable_install_costs.size == 0
			all_applicable_install_costs = InstallationCost.find(:all, :conditions => ["account_id = ? and min_wheel_diameter <= ? and max_wheel_diameter >= ?", 0, wheel_diameter, wheel_diameter], :order => 'ea_install_price desc')
		end

		if all_applicable_install_costs.nil? || all_applicable_install_costs.size == 0
			return InstallationCost.new(:ea_install_price => 15)
		else
			all_applicable_install_costs = InstallationCost.find(:all, :conditions => ["account_id = ? and min_wheel_diameter <= ? and max_wheel_diameter >= ?", 0, wheel_diameter, wheel_diameter], :order => 'ea_install_price desc')
			return all_applicable_install_costs.first
		end
	end

	def self.get_installation_cost(account_id, tire_store_id, wheel_diameter, run_flat=false)
		record = InstallationCost.get_installation_record(account_id, tire_store_id, wheel_diameter, run_flat)
		if record
			return record.ea_install_price
		end
    end

	def self.get_installation_cost_parts(account_id, tire_store_id, wheel_diameter, run_flat=false)
		record = InstallationCost.get_installation_record(account_id, tire_store_id, wheel_diameter, run_flat)
		if record
			return record.parts_portion
		end
    end

	def self.get_installation_cost_labor(account_id, tire_store_id, wheel_diameter, run_flat=false)
		record = InstallationCost.get_installation_record(account_id, tire_store_id, wheel_diameter, run_flat)
		if record
			return record.labor_portion
		end
    end

    # parts are often taxable whereas labor is often not taxable
    def parts_portion
    	if self.other_properties['parts_portion'].blank?
    		return 0.00
    	else
    		begin
    			return self.other_properties['parts_portion'].to_money
    		rescue
    			return 0.00
    		end
    	end
    end

    def parts_portion=(val)
    	if val.blank?
    		self.destroy_key(:other_properties, :parts_portion)
    	else
    		self.other_properties['parts_portion'] = val
    	end
    end

    def labor_portion
    	self.ea_install_price.to_money - parts_portion.to_money
    end
end
