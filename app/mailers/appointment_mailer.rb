class AppointmentMailer < ActionMailer::Base
	default from: "TreadHunter Appointments <mail@treadhunter.com>"

	def send_appt_confirmation_to_seller(appointment)
		@appointment = Appointment.find(appointment.id)
		@tire_store = @appointment.tire_store
		@order = @appointment.order
		@tire_listing = @appointment.tire_listing

		@paid_for = false
		if !@order.nil?
			@paid_for = @order.has_been_paid_for
		end

		if @appointment.confirmed_flag
			mail(:to => @appointment.my_seller_email,
		     		:subject => "TreadHunter - Appointment Confirmed for #{@appointment.buyer_name}")
		else
			mail(:to => "bounce@treadhunter.com",
				:body => nil,
				:subject => "no subject")
		end
	end

	def send_appt_confirmation_to_buyer(appointment)
		@appointment = Appointment.find(appointment.id)
		@tire_store = @appointment.tire_store
		@order = @appointment.order
		@tire_listing = @appointment.tire_listing

		@paid_for = false
		if !@order.nil?
			@paid_for = @order.has_been_paid_for
		end
		
		if @appointment.confirmed_flag
			mail(:to => @appointment.my_seller_email,
	     			:subject => "TreadHunter - Appointment Confirmed for #{@appointment.confirmed_time}")
		else			
			mail(:to => "bounce@treadhunter.com",
				:body => nil,
				:subject => "no subject")
		end
	end
end
