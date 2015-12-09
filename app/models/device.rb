class Device < ActiveRecord::Base  
	attr_accessible :enabled, :token, :user, :platform
	belongs_to :user
	validates_uniqueness_of :token, :scope => :user_id

	def self.find_push_message_by_device_and_guid(device, guid)
		PushMessageDetail.find_by_device_and_guid(device, guid)
		# Push::Message.find(:first, :conditions => ["device = ? and properties like ?", device, '%' + guid + '%'])
	end

	def self.find_push_message_by_guid(guid)
		PushMessageDetail.find_by_guid(guid)
		# Push::Message.find(:first, :conditions => ["device = ? and properties like ?", device, '%' + guid + '%'])
	end

	def self.find_orig_push_message_by_guid(guid)
		Push::Message.find(:first, :conditions => ["properties like ?", '%' + guid + '%'])
	end

	def self.ReservationGCM(device, reservation)
		Push::MessageGcm.create(app: 'TireSeller',
			device: "#{device.token}",
			payload: { 
				id: "#{reservation.id}", 
				quantity: "#{reservation.quantity}", 
				description: "#{reservation.listing_description}", 
				price: "#{reservation.listing_price}", 
				email: "#{reservation.buyer_email}", 
				name: "#{reservation.name}",
				phone: "#{reservation.formatted_phone}",
				created_at: "#{reservation.created_at}",
				tire_store_id: "#{reservation.tire_store.id}" 
			}, 
		collapse_key: 'Reservations')
	end

	def self.ReservationAPNS(device, reservation)
		g = Device.GUID
		p = Push::MessageApns.create(
			app: 'TireSeller',
			device: "#{device.token}",
			alert: 'New Reservation',
			sound: '1.aiff',
			badge: 1,
			expiry: 1.day.to_i,
			attributes_for_device: {key: 'Reservations',
				id: "#{reservation.id}", 
				#quantity: "#{reservation.quantity}", 
				description: "#{reservation.listing_description.truncate(128)}", 
				price: "#{reservation.listing_price}", 
				guid: "#{g}",
				#email: "#{reservation.buyer_email}", 
				name: "#{reservation.name.truncate(32)}",
				#phone: "#{reservation.formatted_phone}",
				#created_at: "#{reservation.created_at}",
				tire_store_id: "#{reservation.tire_store.id}"})

		if p
			PushMessageDetail.create(device: "#{device.token}",
				push_message_id: p.id,
				guid: "#{g}",
				device: "#{device.token}",
				tire_store_id: "#{reservation.tire_store.id}",
				attributes_for_device: {key: 'Reservations',
					id: "#{reservation.id}", 
					quantity: "#{reservation.quantity}", 
					description: "#{reservation.listing_description}", 
					price: "#{reservation.listing_price}", 
					email: "#{reservation.buyer_email}",
					name: "#{reservation.name}",
					phone: "#{reservation.formatted_phone}",
					created_at: "#{reservation.created_at}"})
		end	
	end

	def self.notify_seller_reservation(reservation)
		if !reservation.nil?
			Device.find_all_by_account_id(reservation.tire_store.account_id).each do |device|
				if device.platform == 'android'
					Device.ReservationGCM(device, reservation)
				else
					Device.ReservationAPNS(device, reservation)
				end
			end
		end
	end

	def self.AppointmentGCM(device, appointment)
		Push::MessageGcm.create(app: 'TireSeller',
			device: "#{device.token}",
			payload: { 
				appointment_id: "#{appointment.id}",
				user_id: (appointment.user_id.nil? ? "-1" : "#{appointment.user_id}"),
				tire_store_id: "#{appointment.tire_store_id}",
				tire_listing_id: "#{appointment.tire_listing_id}",
				reservation_id: "#{appointment.reservation_id}",
				buyer_email: "#{appointment.buyer_email}",
				buyer_name: "#{appointment.buyer_name}",
				buyer_address: "#{appointment.buyer_address_formatted}",
				buyer_phone: "#{appointment.buyer_phone}",
				contact_path: "#{appointment.preferred_contact_path}",
				notes: "#{appointment.notes}",
				primary_request_time: "#{appointment.primary_request_time}",
				secondary_request_time: "#{appointment.secondary_request_time}",
				vehicle_mileage: "#{appointment.vehicle_mileage}",
				vehicle_name: "#{appointment.vehicle_name}",
				services: "#{appointment.services_list.join(' | ')}",
				order_id: "#{appointment.order_id}",
				created_at: Time.now
			}, 
		collapse_key: 'Appointment Request')
	end

	def self.AppointmentAPNS(device, appointment)
		g = Device.GUID
		p = Push::MessageApns.create(
			app: 'TireSeller',
			device: "#{device.token}",
			alert: "Appt Req from #{appointment.buyer_name.truncate(12)}",
			sound: '1.aiff',
			badge: 1,
			expiry: 1.day.to_i,
			attributes_for_device: {key: 'Appt',
				appointment_id: "#{appointment.id}",
				#user_id: (appointment.user_id.nil? ? "-1" : "#{appointment.user_id}"),
				tire_store_id: "#{appointment.tire_store_id}",
				#tire_listing_id: "#{appointment.tire_listing_id}",
				#reservation_id: "#{appointment.reservation_id}",
				#buyer_email: "#{appointment.buyer_email.truncate(12)}",
				#buyer_name: "#{appointment.buyer_name.truncate(16)}",
				guid: "#{g}",
				#buyer_address: "#{appointment.buyer_address_formatted}",
				#buyer_phone: "#{appointment.buyer_phone}",
				#contact_path: "#{appointment.preferred_contact_path}",
				#notes: "#{appointment.notes}",
				#primary_request_time: "#{appointment.primary_request_time}",
				#secondary_request_time: "#{appointment.secondary_request_time}",
				#vehicle_mileage: "#{appointment.vehicle_mileage}",
				#vehicle_name: "#{appointment.vehicle_name}",
				#services: "#{appointment.services_list.join(' | ')}",
				created_at: Time.now})
		if p
			if p.id.blank?
				q = Device.find_orig_push_message_by_guid(g)
				if q
					p = q 
				else
					puts "Still could not find...sigh..."
				end
			end
			PushMessageDetail.create(device: "#{device.token}",
				push_message_id: p.id,
				guid: "#{g}",
				device: "#{device.token}",
				tire_store_id: "#{appointment.tire_store_id}",
				attributes_for_device: {key: 'Appointment Request',
					appointment_id: "#{appointment.id}",
					user_id: (appointment.user_id.nil? ? "-1" : "#{appointment.user_id}"),
					tire_listing_id: "#{appointment.tire_listing_id}",
					reservation_id: "#{appointment.reservation_id}",
					buyer_email: "#{appointment.buyer_email}",
					buyer_name: "#{appointment.buyer_name}",
					buyer_address: "#{appointment.buyer_address_formatted}",
					buyer_phone: "#{appointment.buyer_phone}",
					contact_path: "#{appointment.preferred_contact_path}",
					notes: "#{appointment.notes}",
					primary_request_time: "#{appointment.primary_request_time}",
					secondary_request_time: "#{appointment.secondary_request_time}",
					vehicle_mileage: "#{appointment.vehicle_mileage}",
					vehicle_name: "#{appointment.vehicle_name}",
					services: "#{appointment.services_list.join(' | ')}",
					created_at: Time.now})
		end
	end

	def self.notify_seller_appointment_request(appointment)
		if !appointment.nil?
			Device.find_all_by_account_id(appointment.tire_store.account_id).each do |device|
				if device.platform == 'android'
					puts "Sending seller appointment - Android - #{device.id}"
					Device.AppointmentGCM(device, appointment)
				else
					puts "Sending seller appointment - IOS - #{device.id}"
					Device.AppointmentAPNS(device, appointment)
				end
			end
		end
	end

	def self.ContactEmailGCM(device, contact_seller)
		Push::MessageGcm.create(app: 'TireSeller',
			device: "#{device.token}",
			payload: { 
				message: "#{contact_seller.content}",
				email: "#{contact_seller.email}",
				name: "#{contact_seller.sender_name}",
				phone: "#{contact_seller.phone}",
				tire_store_id: "#{contact_seller.tire_store_id}",
				created_at: Time.now
			}, 
		collapse_key: 'User Messages')
	end

	def self.ContactEmailAPNS(device, contact_seller)
		g = Device.GUID
		p = Push::MessageApns.create(
			app: 'TireSeller',
			device: "#{device.token}",
			alert: 'New User Message',
			sound: '1.aiff',
			badge: 1,
			expiry: 1.day.to_i,
			attributes_for_device: {key: 'User Messages',
				#message: "#{contact_seller.content.truncate(32)}",
				guid: "#{g}",
				email: "#{contact_seller.email.truncate(32)}",
				name: "#{contact_seller.sender_name.truncate(32)}",
				#phone: "#{contact_seller.phone.truncate(16)}",
				tire_store_id: "#{contact_seller.tire_store_id}",
				created_at: Time.now})
		if p 
			PushMessageDetail.create(device: "#{device.token}",
				push_message_id: p.id,
				guid: "#{g}",
				device: "#{device.token}",
				tire_store_id: "#{contact_seller.tire_store_id}",
				attributes_for_device: {key: 'User Messages',
					message: "#{contact_seller.content}",
					email: "#{contact_seller.email}",
					name: "#{contact_seller.sender_name}",
					phone: "#{contact_seller.phone}",
					created_at: Time.now})
		end
	end

	def self.notify_seller_contact_email(contact_seller)
		if !contact_seller.nil?
			Device.find_all_by_account_id(contact_seller.tire_store.account_id).each do |device|
				if device.platform == 'android'
					Device.ContactEmailGCM(device, contact_seller)
				else
					Device.ContactEmailAPNS(device, contact_seller)
				end
			end
		end
	end

	def self.TestMessageAPNS(device_token)
		Push::MessageApns.create(
			app: 'TireSeller',
			expiry: 1.day.to_i,
			device: device_token)
	end

	def self.SystemMessageGCM(device, tire_store, msg)
		Push::MessageGcm.create(app: 'TireSeller',
			device: "#{device.token}",
			payload: { 
				message: "#{msg}",
				tire_store_id: "#{tire_store.id}",
				created_at: Time.now
			}, 
		collapse_key: 'System')
	end

	def self.SystemMessageAPNS(device, tire_store, msg)
		g = Device.GUID
		p = Push::MessageApns.create(
			app: 'TireSeller',
			device: "#{device.token}",
			alert: 'New System Message',
			sound: '1.aiff',
			badge: 1,
			expiry: 1.day.to_i,
			attributes_for_device: {key: 'System Messages',
				message: "#{msg.truncate(32)}",
				guid: "#{g}",
				tire_store_id: "#{tire_store.id}",
				created_at: Time.now})
		if p 
			PushMessageDetail.create(device: "#{device.token}",
				push_message_id: p.id,
				guid: "#{g}",
				device: "#{device.token}",
				tire_store_id: "#{tire_store.id}",
				attributes_for_device: {key: 'System Messages',
					message: "#{msg}",
					created_at: Time.now})
		end
	end

	def self.broadcast_system_message(msg)
		Device.find(:all).each do |device|
			if device.platform == 'android'
				Device.SystemMessageGCM(device, TireStore.find(device.tire_store_id), msg)
			else
				Device.SystemMessageAPNS(device, TireStore.find(device.tire_store_id), msg)
			end
		end
	end

	def self.notify_seller_system_message(tire_store, msg)
		if !tire_store.nil?
			Device.find_all_by_account_id(tire_store.account_id).each do |device|
				if device.platform == 'android'
					Device.SystemMessageGCM(device, tire_store, msg)
				else
					Device.SystemMessageAPNS(device, tire_store, msg)
				end
			end
		end
	end

	def self.GenericMessageGCM(device, tire_store, content_title, small_icon_description, big_text, content_text)
		Push::MessageGcm.create(app: 'TireSeller',
			device: "#{device.token}",
			payload: { 
				content_title: "#{content_title}",
				small_icon_description: "#{small_icon_description}",
				big_text: "#{big_text}",
				content_text: "#{content_text}",
				tire_store_id: "#{tire_store.id}",
				created_at: Time.now
			}, 
		collapse_key: 'Generic')
	end

	def self.GenericMessageAPNS(device, tire_store, content_title, small_icon_description, big_text, content_text)
		g = Device.GUID
		p = Push::MessageApns.create(
			app: 'TireSeller',
			device: "#{device.token}",
			alert: 'New Generic Message',
			sound: '1.aiff',
			badge: 1,
			expiry: 1.day.to_i,
			attributes_for_device: {key: 'Generic Messages',
				content_title: "#{content_title.truncate(32)}",
				guid: "#{g}",
				#small_icon_description: "#{small_icon_description}",
				#big_text: "#{big_text.truncate(32)}",
				#content_text: "#{content_text.truncate(12)}",
				tire_store_id: "#{tire_store.id}",
				created_at: Time.now})
		if p 
			PushMessageDetail.create(device: "#{device.token}",
				push_message_id: p.id,
				guid: "#{g}",
				device: "#{device.token}",
				tire_store_id: "#{tire_store.id}",
				attributes_for_device: {key: 'Generic Messages',
					content_title: "#{content_title}",
					small_icon_description: "#{small_icon_description}",
					big_text: "#{big_text}",
					content_text: "#{content_text}",
					created_at: Time.now})
		end
	end

	def self.notify_seller_generic_message(tire_store, content_title, small_icon_description, big_text, content_text)
		if !tire_store.nil?
			Device.find_all_by_account_id(tire_store.account_id).each do |device|
				if device.platform == 'android'
					Device.GenericMessageGCM(device, tire_store, content_title, small_icon_description, big_text, content_text)
				else
					Device.GenericMessageAPNS(device, tire_store, content_title, small_icon_description, big_text, content_text)
				end
			end
		end
	end

	def self.GUID
		SecureRandom.uuid
	end

	def self.CreateTestMessagesIOS(email_address)
		target_user = User.find_by_email(email_address)
		device = Device.find_all_by_user_id_and_platform(target_user.id, "ios").last
		tire_store = TireStore.find_by_id(device.tire_store_id)

		if tire_store && tire_store.reservations && tire_store.reservations.size > 0
			reservation = tire_store.reservations.last

			puts "Creating Reservation notification"
			Device.ReservationAPNS(device, reservation)
		end

		if tire_store

			a = Appointment.new

			begin
				a.tire_store_id = tire_store.id 
				a.reservation_id = -1 
				a.user_id = nil 
				a.buyer_email = Faker::Internet.email
				a.buyer_name = Faker::Name.name
				a.buyer_phone = Faker::PhoneNumber.phone_number
				a.buyer_address = Faker::Address.street_address
				a.buyer_city = 'Atlanta'
				a.buyer_state = 'GA'
				a.buyer_zip = '30335'
				a.preferred_contact_path = 1
				a.notes = 'This is what a customer would enter for the notes'
				a.confirmed_flag = false
				a.rejected_flag = false
				a.request_date_primary = date_to_add = Appointment.date_of_next("Tuesday")
				a.request_hour_primary =  "15:00"
				a.request_date_secondary = Appointment.date_of_next(Date::DAYNAMES[rand(6)])
				a.request_hour_secondary = "10:00"
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

				l = TireListing.find_all_by_tire_store_id_and_tire_size_id_and_is_new(tire_store.id, AutoOption.find(a.auto_option_id).tire_size_id, true)
				if l && l.size > 0
					a.tire_listing_id = l.first.id
				else
					if tire_store.new_tirelistings && tire_store.new_tirelistings.size > 0
						a.tire_listing_id = tire_store.new_tirelistings.first.id
					end
				end

				puts "Creating appointment notification"
				if !a.save
					puts "#{a.errors.to_s}"
				end
				# Device.AppointmentGCM(device, a)
			rescue Exception => e 
				puts "failed to save appointment: #{e.to_s}"
				puts e.backtrace.join("\n")
			end

    		contact_seller = ContactSeller.new(:id => 1,
									          :email => "madeup@customer.com",
									          :sender_name => "Fake Customer",
									          :phone => "7705551212",
									          :content => "This is a message from a fake customer",
									          :tire_store_id => tire_store.id)

    		puts "Creating Contact Email notification"
			ContactEmailAPNS(device, contact_seller)

			puts "Creating System notification"
			Device.SystemMessageAPNS(device, tire_store, "This is a system message from TreadHunter - we might use this to let the users know to update their devices, or they could be sponsored messages from distributors to let users know about specials, etc.")

			puts "Creating Generic notification"
			Device.GenericMessageAPNS(device, tire_store, "Sample Generic Message Title", "launcher", "Whoa - Big Text!", "This is called a 'generic message' and can be used to send devices whatever type of message we want.")
		end
	end

	def self.CreateTestMessagesAndroid(email_address)
		target_user = User.find_by_email(email_address)
		device = Device.find_all_by_user_id_and_platform(target_user.id, "android").last
		tire_store = TireStore.find_by_id(device.tire_store_id)

		if tire_store && tire_store.reservations && tire_store.reservations.size > 0
			reservation = tire_store.reservations.last

			Device.ReservationGCM(device, reservation)
		end

		if tire_store
			a = Appointment.new

			begin
				a.tire_store_id = tire_store.id 
				a.reservation_id = -1 
				a.user_id = nil 
				a.buyer_email = Faker::Internet.email
				a.buyer_name = Faker::Name.name
				a.buyer_phone = Faker::PhoneNumber.phone_number
				a.buyer_address = Faker::Address.street_address
				a.buyer_city = 'Atlanta'
				a.buyer_state = 'GA'
				a.buyer_zip = '30335'
				a.preferred_contact_path = 1
				a.notes = 'This is what a customer would enter for the notes'
				a.confirmed_flag = false
				a.rejected_flag = false
				a.request_date_primary = date_to_add = Appointment.date_of_next("Tuesday")
				a.request_hour_primary =  "15:00"
				a.request_date_secondary = Appointment.date_of_next(Date::DAYNAMES[rand(6)])
				a.request_hour_secondary = "10:00"
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

				l = TireListing.find_all_by_tire_store_id_and_tire_size_id_and_is_new(tire_store.id, AutoOption.find(a.auto_option_id).tire_size_id, true)
				if l && l.size > 0
					a.tire_listing_id = l.first.id
				else
					if tire_store.new_tirelistings && tire_store.new_tirelistings.size > 0
						a.tire_listing_id = tire_store.new_tirelistings.first.id
					end
				end

				if !a.save
					puts "#{a.errors.to_s}"
				end
				# Device.AppointmentGCM(device, a)
			rescue Exception => e 
				puts "failed to save appointment: #{e.to_s}"
			end
		end

    	contact_seller = ContactSeller.new(:id => 1,
									          :email => "madeup@customer.com",
									          :sender_name => "Fake Customer",
									          :phone => "7705551212",
									          :content => "This is a message from a fake customer",
									          :tire_store_id => tire_store.id)
    	puts "Createing a Contact Us Email"
		ContactEmailGCM(device, contact_seller)

		puts "Creating a System Message"
		Device.SystemMessageGCM(device, tire_store, "This is a system message from TreadHunter - we might use this to let the users know to update their devices, or they could be sponsored messages from distributors to let users know about specials, etc.")

		puts "Creating a Generic Message"
		Device.GenericMessageGCM(device, tire_store, "Sample Generic Message Title", "launcher", "Whoa - Big Text!", "This is called a 'generic message' and can be used to send devices whatever type of message we want.")
	end
end 
