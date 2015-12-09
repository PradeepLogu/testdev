include TireStoresHelper

class Appointment < ActiveRecord::Base
	attr_accessible :id, :tire_store_id, :tire_listing_id, :reservation_id
	attr_accessible :user_id
	attr_accessible :buyer_email, :buyer_name, :buyer_phone
	attr_accessible :buyer_address, :buyer_city, :buyer_state, :buyer_zip
	attr_accessible :preferred_contact_path
	attr_accessible :notes, :confirmed_flag, :rejected_flag
	attr_accessible :request_date_primary, :request_hour_primary
	attr_accessible :request_date_secondary, :request_hour_secondary
	attr_accessible :confirm_date, :confirm_hour
	attr_accessible :auto_year_id, :auto_option_id, :auto_model_id
	attr_accessible :auto_manufacturer_id, :vehicle_mileage

	attr_accessible :quantity, :price

	attr_accessor :send_confirmations
	attr_accessor :notification_sent

	serialize :services, ActiveRecord::Coders::Hstore

	validates_presence_of :buyer_name, :message => "You must provide a name to schedule your service."

	#with_options :if => (:preferred_contact_path.downcase == 'phone') do |phone_buyer|
	#	phone_buyer.validates :buyer_phone, presence: true
	#end

	validates_presence_of :request_hour_primary, :message => "You must provide a requested date and time."
	validates_presence_of :request_hour_secondary, :message => "You must provide a secondary requested date and time."

	after_save :send_notifications

	after_initialize :init

	has_one :order

	before_validation :validate_phone
	before_validation :validate_reservation_id
	before_validation :validate_confirmed_flag
	before_validation :validate_rejected_flag

	belongs_to :tire_store
	belongs_to :tire_listing

	validate :validate_contact_path, message: "You have included a banned word in your message."

	composed_of :price,
		:class_name  => "Money",
		:mapping     => [%w(price cents), %w(currency currency_as_string)],
		:constructor => Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
		:converter   => Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }


	scope "store_appointments", lambda { |tire_store_id, query_date| 
											if query_date - 10.days < Date.today
												start_date = Date.today
											else
												start_date = query_date - 10.days
											end
											end_date = query_date + 10.days
											where("rejected_flag = false and tire_store_id = ? and 
														((confirmed_flag = true and confirm_date >= ? and confirm_date <= ?) or 
														 (confirmed_flag = false and request_date_primary >= ? and request_date_primary <= ?) or
														 (confirmed_flag = false and request_date_secondary >= ? and request_date_secondary <= ?))",
                            				tire_store_id, start_date, end_date, start_date, 
                            				end_date, start_date, end_date).order(:request_date_primary) }


	scope "store_appointments_with_range", lambda { |tire_store_id, query_date, num_days|
											if query_date - num_days.days < Date.today
												start_date = Date.today
											else
												start_date = query_date - num_days.days
											end
											end_date = query_date + num_days.days
											where_clause = ("rejected_flag = false and tire_store_id = #{tire_store_id} and 
														((confirmed_flag = true and confirm_date >= '#{start_date}' and confirm_date <= '#{end_date}') or 
														 (confirmed_flag = false and request_date_primary >= '#{start_date}' and request_date_primary <= '#{end_date}') or
														 (confirmed_flag = false and request_date_secondary >= '#{start_date}' and request_date_secondary <= '#{end_date}'))")

                            				#puts "Where clause!!!: #{where_clause} - #{query_date} #{start_date} #{end_date} - #{num_days}"
                            				where(where_clause).order(:request_date_primary) }

	scope "all_store_appointments_with_range", lambda { |tire_store_id, query_date, num_days|
											start_date = query_date
											end_date = query_date + num_days.days
											where_clause = ("rejected_flag = false and tire_store_id = #{tire_store_id} and 
														((confirmed_flag = true and confirm_date >= '#{start_date}' and confirm_date <= '#{end_date}') or 
														 (confirmed_flag = false and request_date_primary >= '#{start_date}' and request_date_primary <= '#{end_date}') or
														 (confirmed_flag = false and request_date_secondary >= '#{start_date}' and request_date_secondary <= '#{end_date}'))")

                            				#puts "Where clause!!!: #{where_clause} - #{query_date} #{start_date} #{end_date} - #{num_days}"
                            				where(where_clause).order(:request_date_primary) }

	def self.account_appointments_with_range(account_id, query_date, num_days)
		if query_date - num_days.days < Date.today
			start_date = Date.today
		else
			start_date = query_date - num_days.days
		end
		end_date = query_date + num_days.days
		tire_store_ids = TireStore.find_all_by_account_id(account_id).map(&:id)

		Appointment.where("rejected_flag = false and tire_store_id in (?) and 
			((confirmed_flag = true and confirm_date >= '#{start_date}' and confirm_date <= '#{end_date}') or 
			 (confirmed_flag = false and request_date_primary >= '#{start_date}' and request_date_primary <= '#{end_date}') or
			 (confirmed_flag = false and request_date_secondary >= '#{start_date}' and request_date_secondary <= '#{end_date}'))",
			tire_store_ids)
	end

	def self.store_appointments_by_day(tire_store_id, start_date, end_date)
		result = []
		sql = "select appt_date, sum(cnt) from 
		(
		select request_date_primary appt_date, count(*) cnt from appointments
		where rejected_flag = false
		and confirmed_flag = false
		and tire_store_id = #{tire_store_id}
		and request_date_primary >= '#{start_date}'
		and request_date_primary <= '#{end_date}'
		group by appt_date
		union
		select request_date_secondary appt_date, count(*) cnt from appointments
		where rejected_flag = false
		and confirmed_flag = false
		and tire_store_id = #{tire_store_id}
		and request_date_secondary >= '#{start_date}'
		and request_date_secondary <= '#{end_date}'
		group by appt_date
		union
		select confirm_date appt_date, count(*) cnt from appointments
		where rejected_flag = false
		and confirmed_flag = true
		and tire_store_id = #{tire_store_id}
		and confirm_date >= '#{start_date}'
		and confirm_date <= '#{end_date}'
		group by appt_date
		)
		as all_appointments
		group by appt_date"

    	ActiveRecord::Base.connection.execute(sql).each do |a|
    		result << [a["appt_date"], a["sum"]]
    	end

    	return result
	end

	def init
		self.request_date_primary = Date.today + 1.day if self.request_date_primary.nil?
		self.request_date_secondary = Date.today + 2.days if self.request_hour_secondary.nil?
		self.rejected_flag = false if self.rejected_flag.nil?
		self.confirmed_flag = false if self.confirmed_flag.nil?
		self.confirm_date = Date.today if self.confirm_date.nil?
		self.confirm_hour = "" if self.confirm_hour.nil?

		self.send_confirmations = false
		self.notification_sent = false
	end

	def reject_appointment
		self.rejected_flag = true
		self.save
	end

	def confirm_primary_appointment
		self.set_confirmed_appointment(self.request_date_primary, self.request_hour_primary)
	end

	def confirm_secondary_appointment
		self.set_confirmed_appointment(self.request_date_secondary, self.request_hour_secondary)
	end

	def my_seller_email
		if !self.order.nil?
			return self.order.my_seller_email
		else
			return self.tire_store.contact_email
		end
	end

	def set_confirmed_appointment(confirm_date, confirm_hour)
        self.confirmed_flag = true
        self.confirm_date = confirm_date
        self.confirm_hour = confirm_hour
        self.send_confirmations = true
        self.save
	end

	def self.date_of_next(day)
		date  = Date.parse(day)
		delta = date > Date.today ? 0 : 7
		date + delta
	end

	def self.find_random_vehicle
		@manus = AutoManufacturer.where("name in ('Honda', 'Toyota', 'Kia')")
		@selected_manu = @manus[rand(@manus.size)]

		@models = @selected_manu.auto_models
		@selected_model = @models[rand(@models.size)]

		@years = @selected_model.auto_years
		@selected_year = @years[rand(@years.size)]

		@options = @selected_year.auto_options
		@selected_option = @options[rand(@options.size)]

		return @selected_manu.id, @selected_model.id, @selected_year.id, @selected_option.id
	end

	def add_service_id_to_appointment(service_id)
		self.services = {} if self.services == ""
		self.services = (services || {}).merge(service_id.to_s => "service_id")
	end

	def has_service?(service_id)
		if self.services[service_id.to_s] == "service_id"
			return true
		else
			return false 
		end
	end

	def buyer_address_formatted
		return "#{self.buyer_address}, #{self.buyer_city} #{self.buyer_state} #{self.buyer_zip}"
	end

	def confirmed_time
		@dt = DateTime.parse("#{self.confirm_date} #{self.confirm_hour}")
		@dt.strftime("%A, %B %-d, %Y %H:00")
	end

	def confirmed_time_short
		@dt = DateTime.parse("#{self.confirm_date} #{self.confirm_hour}")
		@dt.strftime("%Y/%m/%d %H:00")
	end

	def primary_request_time
		@dt = DateTime.parse("#{self.request_date_primary} #{self.request_hour_primary}")
		@dt.strftime("%A, %B %-d, %Y %H:00")
	end

	def primary_request_time_short
		@dt = DateTime.parse("#{self.request_date_primary} #{self.request_hour_primary}")
		@dt.strftime("%Y/%m/%d %H:00")
	end

	def secondary_request_time
		@dt = DateTime.parse("#{self.request_date_secondary} #{self.request_hour_secondary}")
		@dt.strftime("%A, %B %-d, %Y %H:00")
	end

	def secondary_request_time_short
		@dt = DateTime.parse("#{self.request_date_secondary} #{self.request_hour_secondary}")
		@dt.strftime("%Y/%m/%d %H:00")
	end

	def confirm_request_time
		@dt = DateTime.parse("#{self.confirm_date} #{self.confirm_hour}")
		@dt.strftime("%A, %B %-d, %Y %H:00")
	end

	def vehicle_name
		result = ""

		if !self.auto_manufacturer_id.nil? &&
			!self.auto_model_id.nil? &&
			!self.auto_year_id.nil? &&
			!self.auto_option_id.nil?
			manu = AutoManufacturer.find(self.auto_manufacturer_id)
			if manu
				model = AutoModel.find(self.auto_model_id)
				if model 
					year = AutoYear.find(self.auto_year_id)
					if year
						option = AutoOption.find(self.auto_option_id)
						if option 
							result = "#{year.modelyear} #{manu.name} #{model.name} (#{option.name})"
						end
					end
				end
			end
		end

		return result
	end

	def services_list
		result = []
		self.services.keys.each do |k|
			if self.services[k] == "service_id"
				result << Service.find(k).service_name
			end
		end
		result
	end

	def send_notifications
		puts "*** send_notifications *** - #{self.confirmed_flag} #{send_confirmations} #{self.notification_sent} - Order: #{self.order_id}"
		if self.confirmed_flag && send_confirmations
			# need to send a confirmation notice
			if self.get_preferred_contact_path_string == "Text"
				# send a confirmation text
				puts "*** SENDING CONFIRMATION TEXT TO #{self.buyer_phone}"
				@tire_store = TireStore.find(self.tire_store_id)
				ts = TextSender.new()
				ts.send_text(self.buyer_phone, "Your appointment is confirmed for #{self.confirm_request_time} with #{@tire_store.name}, #{@tire_store.full_address}.")
			elsif self.get_preferred_contact_path_string == "Phone"
				# do nothing....
			elsif self.get_preferred_contact_path_string == "Email"
				# send emails
				AppointmentMailer.delay.send_appt_confirmation_to_buyer(self)
			end

			AppointmentMailer.delay.send_appt_confirmation_to_seller(self)

			self.send_confirmations = false
		else # if self.created_at >= Time.now - 5.seconds
			if !notification_sent
				self.notification_sent = true
				puts "Sending notification: ID: #{self.id}"
				Device.delay.notify_seller_appointment_request(self)
			end
		#else
		#	puts "*** NOT A NEW RECORD ***"
		end
	end

	def can_do_ecomm
		if self.tire_listing
			return self.tire_listing.can_do_ecomm?
		else
			return false
		end
	end

	def formatted_buyer_phone
		number_to_phone(buyer_phone)
	end

	def self.create_test_appointments
		t = TireStore.find_by_name("Jason's Tires")

		if t.nil?
			t = TireStore.find_by_name("Jason's Tires BETA TEST PAGE")
		end

		(0..6).each do |i|
			if !t.day_is_closed?(i)
				weekday = Date::DAYNAMES[i]
				date_to_add = Appointment.date_of_next(weekday)

				puts weekday

				(0..23).each do |j|
					if t.is_store_open_on_day_at_time?(i, "#{j}:00")
						# let's say there's a 30% chance that someone
						# wants an appt at a given time.
						if 1 + rand(10) >= 8
							a = Appointment.new

							begin
								a.tire_store_id = t.id 
								a.reservation_id = -1 
								a.user_id = nil 
								a.buyer_email = Faker::Internet.email
								a.buyer_name = Faker::Name.name
								a.buyer_phone = "404-431-3131" #Faker::PhoneNumber.phone_number
								a.buyer_address = Faker::Address.street_address
								a.buyer_city = 'Atlanta'
								a.buyer_state = 'GA'
								a.buyer_zip = '30335'
								a.preferred_contact_path = 2 # text
								a.notes = 'This is what a customer would enter for the notes'
								a.confirmed_flag = false
								a.rejected_flag = false
								a.request_date_primary = date_to_add
								a.request_hour_primary =  "#{j}:00"
								a.request_date_secondary = Appointment.date_of_next(Date::DAYNAMES[rand(6)])
								a.request_hour_secondary = "#{9 + rand(9)}:00"
								a.confirm_date = Date.parse('2014-01-01')
								a.confirm_hour = "00:00"
								a.auto_manufacturer_id, a.auto_model_id, a.auto_year_id, a.auto_option_id = Appointment.find_random_vehicle()

								#= AutoManufacturer.find_by_name('Honda').id
								#a.auto_model_id = AutoModel.find_by_auto_manufacturer_id_and_name(a.auto_manufacturer_id, 'Accord').id
								#a.auto_year_id = AutoYear.find_by_auto_model_id_and_modelyear(a.auto_model_id, '2009').id
								#a.auto_option_id = AutoOption.find_all_by_auto_year_id(a.auto_year_id).first.id
								a.vehicle_mileage = "#{50 + rand(70)},000"

								a.add_service_id_to_appointment(Service.find_by_service_name('Air Filters').id)
								a.add_service_id_to_appointment(Service.find_by_service_name('Oil Change Service').id)
								a.add_service_id_to_appointment(Service.find_by_service_name('Belts and Hoses').id)

								l = TireListing.find_all_by_tire_store_id_and_tire_size_id_and_is_new(t.id, AutoOption.find(a.auto_option_id).tire_size_id, true)
								if l && l.size > 0
									a.tire_listing_id = l.first.id
									a.price = l.first.price
    								a.quantity = 4
								else
									if t.new_tirelistings && t.new_tirelistings.size > 0
										a.tire_listing_id = t.new_tirelistings.first.id
										a.price = t.new_tirelistings.first.price
    									a.quantity = 4
									end
								end

								if !a.save
									puts "#{a.errors.to_s}"
								end
							rescue Exception => e 
								puts "failed: #{e.to_s}"
							end
						end
					end
				end
			end
		end

		if false
		a.tire_store_id = t.id 
		a.reservation_id = -1 
		a.user_id = nil 
		a.buyer_email = 'jgonzalez52@gmail.com'
		a.buyer_name = 'Jose Gonzalez'
		a.buyer_phone = '770-555-3822'
		a.buyer_address = '302 E. Main St.'
		a.buyer_city = 'Atlanta'
		a.buyer_state = 'GA'
		a.buyer_zip = '30335'
		a.preferred_contact_path = 0
		a.notes = 'My car needs several maintenance items. Can you squeeze me in for 4 tires and these services on Tuesday afternoon?'
		a.confirmed_flag = false
		a.rejected_flag = false
		a.request_date_primary = Appointment.date_of_next 'Tuesday'
		a.request_hour_primary = '14:00'
		a.request_date_secondary = Appointment.date_of_next 'Thursday'
		a.request_hour_secondary = '09:00'
		a.confirm_date = Date.parse('2014-01-01')
		a.confirm_hour = "00:00"
		a.auto_manufacturer_id = AutoManufacturer.find_by_name('Honda').id
		a.auto_model_id = AutoModel.find_by_auto_manufacturer_id_and_name(a.auto_manufacturer_id, 'Accord').id
		a.auto_year_id = AutoYear.find_by_auto_model_id_and_modelyear(a.auto_model_id, '2009').id
		a.auto_option_id = AutoOption.find_all_by_auto_year_id(a.auto_year_id).first.id
		a.vehicle_mileage = "123,000"

		a.add_service_id_to_appointment(Service.find_by_service_name('Air Filters').id)
		a.add_service_id_to_appointment(Service.find_by_service_name('Oil Change Service').id)
		a.add_service_id_to_appointment(Service.find_by_service_name('Belts and Hoses').id)

		l = TireListing.find_all_by_tire_store_id_and_tire_size_id_and_is_new(t.id, AutoOption.find(a.auto_option_id).tire_size_id, true)
		if l 
			a.tire_listing_id = l.first.id
		else
			a.tire_listing_id = t.new_tirelistings.first.id
		end

		a.save
		end

		# reservation_id, confirm_date should allow nulls
	end

	def self.get_proposed_request_time_and_hour(tire_store, order_dt)
		found_hour = false 
		appt_request_date = nil
		request_hour = nil

		(3..9).each do |days_in_future|
			appt_request_date = order_dt + (days_in_future + rand(4)).days
			if !tire_store.day_is_closed?(appt_request_date.wday)
				# pick a random time when it's open
				found_hour = false
				num_loops = 0
				proposed_hour = 0
				while found_hour == false && num_loops < 10
					num_loops += 1
					proposed_hour = rand(12) + 8
					if tire_store.is_store_open_on_day_at_time?(appt_request_date.wday, "#{proposed_hour}:00")
						found_hour = true
						request_hour = proposed_hour
					end
				end

				if found_hour
					break
				end
			end
			if found_hour
				break
			end
		end
		if found_hour
			return appt_request_date, request_hour
		else
			return nil, nil 
		end
	end

	def self.create_test_orders_and_appointments
		t = TireStore.find_by_name("Jason's Tires")

		if t.nil?
			t = TireStore.find_by_name("Jason's Tires BETA TEST PAGE")
		end

		if t.nil?
			t = TireStore.find_by_name("Jacksonville 9th Street Tires")
		end

		(-365..365).each do |d|
		#(-1..1).each do |d|
			order_dt = Date.today + d.days 
			(0..rand(10)).each do |j| # how many orders per day
				primary_request_date, primary_request_hour = Appointment.get_proposed_request_time_and_hour(t, order_dt)
				secondary_request_date, secondary_request_hour = Appointment.get_proposed_request_time_and_hour(t, order_dt)

				if !primary_request_date.nil? &&
					!primary_request_hour.nil? &&
					!secondary_request_date.nil? &&
					!secondary_request_hour.nil?
					puts "Got it...for order date #{order_dt}, primary=#{primary_request_date} #{primary_request_hour} secondary=#{secondary_request_date} #{secondary_request_hour}"

					a = Appointment.new

					begin
						a.tire_store_id = t.id 
						a.reservation_id = -1 
						a.user_id = nil 
						a.buyer_email = Faker::Internet.email
						a.buyer_name = Faker::Name.name
						a.buyer_phone = "404-431-3131" #Faker::PhoneNumber.phone_number
						a.buyer_address = Faker::Address.street_address
						a.buyer_city = 'Atlanta'
						a.buyer_state = 'GA'
						a.buyer_zip = '30335'
						a.preferred_contact_path = 2 # text
						a.notes = 'This is what a customer would enter for the notes'
						if order_dt < Date.today + 7.days
							a.confirmed_flag = true
							a.confirm_date =primary_request_date
							a.confirm_hour = "#{primary_request_hour}:00"
						else
							a.confirmed_flag = false
							a.confirm_date = Date.parse('2014-01-01')
							a.confirm_hour = "00:00"
						end
						a.rejected_flag = false
						a.request_date_primary = primary_request_date
						a.request_hour_primary =  "#{primary_request_hour}:00"
						a.request_date_secondary = secondary_request_date
						a.request_hour_secondary = "#{secondary_request_hour}:00"
						a.auto_manufacturer_id, a.auto_model_id, a.auto_year_id, a.auto_option_id = Appointment.find_random_vehicle()

						a.vehicle_mileage = "#{50 + rand(70)},000"

						a.add_service_id_to_appointment(Service.find_by_service_name('Air Filters').id)
						a.add_service_id_to_appointment(Service.find_by_service_name('Oil Change Service').id)
						a.add_service_id_to_appointment(Service.find_by_service_name('Belts and Hoses').id)

						l = TireListing.find_all_by_tire_store_id_and_tire_size_id_and_is_new(t.id, AutoOption.find(a.auto_option_id).tire_size_id, true)
						if l && l.size > 0
							a.tire_listing_id = l.first.id
							a.price = l.first.price
							a.quantity = 4
						else
							if t.new_tirelistings && t.new_tirelistings.size > 0
								a.tire_listing_id = t.new_tirelistings.first.id
								a.price = t.new_tirelistings.first.price
								a.quantity = 4
							end
						end

						if !a.save
							puts "Save Failed!"
							puts "#{a.errors.to_s}"
						else
							a.update_attribute(:created_at, order_dt)

							if rand(10) > 2
								# create an accompanying order
	    						@order = Order.new(:tire_listing_id => a.tire_listing_id, :tire_quantity => a.quantity)
	    						@order.status = order_status_array[:created]
	    						@order.calculate_total_order
	    						@order.buyer_email = a.buyer_email
	    						@order.buyer_name = a.buyer_name
	    						@order.buyer_address1 = a.buyer_address
	    						@order.buyer_city = a.buyer_city
	    						@order.buyer_state = a.buyer_state
	    						@order.buyer_zip = a.buyer_zip
	    						@order.buyer_phone = a.buyer_phone
	    						@order.appointment_id = a.id
	    						if @order.save
	    							puts "Order save succeeded..."
	    							@order.update_attribute(:created_at, order_dt)
	    						else
	    							puts "Order save failed...#{@order.errors.to_s}"
	    						end
	    					end
						end
					rescue Exception => e 
						puts "Exception...."
						puts e.backtrace.join("\n")
					end
				else
					puts "Could not get primary or secondary requests..."
				end
			end
		end
		# reservation_id, confirm_date should allow nulls
	end

	def set_mileage(veh_mileage)
		if veh_mileage.nil?
			self.vehicle_mileage = ""
		else
			self.vehicle_mileage = veh_mileage.to_s.gsub!(/\D/, "")
		end
	end

	def validate_phone
		puts "-=----> before validate_phone: #{self.buyer_phone}"
		if self.buyer_phone.nil?
			self.buyer_phone = ""
		else
			self.buyer_phone = self.buyer_phone.gsub(/\D/, '') 
		end

		puts "-=----> validate_phone: #{self.buyer_phone}"
		return true
	end

	def validate_reservation_id
		if self.reservation_id.nil?
			self.reservation_id = -1
		elsif Reservation.find_by_id(self.reservation_id).nil?
			self.reservation_id = -1
		end
		return true
	end

	def validate_confirmed_flag
		if self.confirmed_flag.nil?
			self.confirmed_flag = false 
		else
			begin
				self.confirmed_flag = self.confirmed_flag.to_bool
			rescue
			end
		end

		if self.confirm_date.nil?
			self.confirm_date = Date.today
		end

		if self.confirm_hour.nil?
			self.confirm_hour = ""
		end

		return true
	end

	def validate_rejected_flag
		if self.rejected_flag.nil?
			self.rejected_flag = false 
		else
			begin
				self.rejected_flag = self.rejected_flag.to_bool
			rescue
			end
		end
		return true
	end

	def get_preferred_contact_path_string
		if self.preferred_contact_path == 2
			return "Text"
		elsif self.preferred_contact_path == 0
			return "Phone"
		elsif self.preferred_contact_path == 1
			return "Email"
		else
			return "Phone"
		end
	end

	def validate_contact_path
		if self.get_preferred_contact_path_string == "Text" &&
			self.buyer_phone.size < 10
			errors.add("Phone -", "You must provide a valid phone when requesting text confirmation.")
			return false
		elsif self.get_preferred_contact_path_string == "Phone" &&
			self.buyer_phone.size < 10
			errors.add("Phone -", "You must provide a valid phone when requesting phone confirmation.")
			return false
		elsif self.get_preferred_contact_path_string == "Email" &&
			(self.buyer_email.blank? || !self.buyer_email.to_s.is_valid_email?)
			errors.add("Email -", "You must provide a valid email address when requesting email confirmation.")
			return false
		end
		return true
	end

	def formatted_price
		price.to_s
	end

	def appt_time_short
		if confirmed_flag
			confirmed_time_short
		else
			primary_request_time_short
		end
	end

	def secondary_appt_time_short
		if confirmed_flag
			""
		else
			secondary_request_time_short
		end
	end

	def title_old
		if self.order.nil?
			self.buyer_name
		else
			"#{self.buyer_name}"
		end
	end

	def order_price
		if self.order.nil?
			""
		else
			"$#{self.order.total_order_price.to_money}"
		end
	end

	def title
		self.tire_store.name
	end

	def calendar_line1
		if self.confirmed_flag
			#("00:00" + self.confirm_hour).last(5)
			Time.parse(("00:00" + self.confirm_hour).last(5)).strftime("%l %p")
		else
			#("00:00" + self.request_hour_primary).last(5)
			Time.parse(("00:00" + self.request_hour_primary).last(5)).strftime("%l %p")
		end
	end

	def calendar_sort
		if self.confirmed_flag
			("00:00" + self.confirm_hour).last(5)
		else
			("00:00" + self.request_hour_primary).last(5)
		end
	end

	def start
		if self.confirmed_flag
			Date.parse(self.confirmed_time).to_s
		else
			Date.parse(self.primary_request_time).to_s
		end
	end

	def end
		if self.confirmed_flag
			Date.parse(self.confirmed_time).to_s
		else
			Date.parse(self.primary_request_time).to_s
		end
	end

	def color
		if confirmed_flag
			return "green"
		elsif self.order.nil?
			return "pink"
		else
			return "red"
		end
	end

	def tire_store_name
		return self.tire_store.name
	end

	def order_id
		if self.order.nil?
			nil
		else
			"#{self.order.id}"
		end
	end

	def order_amount
		if self.order.nil?
			nil
		else
			"#{self.order.total_order_price}"
		end
	end

	def tire_description
		if self.order.nil?
			"#{self.quantity} #{self.tire_listing.cc_short_description}"
		else
			"#{self.order.tire_quantity} #{self.order.tire_listing.cc_short_description}"
		end
	end
end