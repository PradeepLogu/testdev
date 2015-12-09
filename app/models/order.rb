include ApplicationHelper

class Order < ActiveRecord::Base
  attr_accessible :appointment_id, :other_properties, :sales_tax_collected, :th_sales_tax_collected
  attr_accessible :th_processing_fee, :th_user_fee, :tire_ea_price
  attr_accessible :tire_listing_id, :tire_quantity, :transfer_amount
  attr_accessible :transfer_id, :user_id, :tire_ea_install_price

  attr_accessible :buyer_email, :buyer_name, :buyer_address1, :buyer_address2, :buyer_city, :buyer_state, :buyer_zip
  attr_accessible :buyer_phone

  attr_accessor :lookup, :transaction

  attr_accessor :tot_tire_price, :tot_install_price, :tot_order_price
  #monetize :tot_tire_price
  #monetize :tot_install_price
  #monetize :tot_order_price

  belongs_to :tire_listing
  belongs_to :appointment
  has_one :tire_store, :through => :tire_listing

  belongs_to :user 

  has_enum_field :status, order_status_array()  
  has_enum_field :inv_status, inventory_status_array()
  serialize :stripe_properties, ActiveRecord::Coders::Hstore

  composed_of :tire_ea_price,
    :class_name  => "Money",
    :mapping     => [%w(tire_ea_price cents), %w(currency currency_as_string)],
    :constructor => Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
    :converter   => Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }
  composed_of :sales_tax_collected,
    :class_name  => "Money",
    :mapping     => [%w(sales_tax_collected cents), %w(currency currency_as_string)],
    :constructor => Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
    :converter   => Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }
  composed_of :th_sales_tax_collected,
    :class_name  => "Money",
    :mapping     => [%w(th_sales_tax_collected cents), %w(currency currency_as_string)],
    :constructor => Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
    :converter   => Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }
  composed_of :th_user_fee,
    :class_name  => "Money",
    :mapping     => [%w(th_user_fee cents), %w(currency currency_as_string)],
    :constructor => Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
    :converter   => Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }
  composed_of :transfer_amount,
    :class_name  => "Money",
    :mapping     => [%w(transfer_amount cents), %w(currency currency_as_string)],
    :constructor => Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
    :converter   => Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }
  composed_of :th_processing_fee,
    :class_name  => "Money",
    :mapping     => [%w(th_processing_fee cents), %w(currency currency_as_string)],
    :constructor => Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
    :converter   => Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }    

  composed_of :tire_ea_install_price,
    :class_name  => "Money",
    :mapping     => [%w(tire_ea_install_price cents), %w(currency currency_as_string)],
    :constructor => Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
    :converter   => Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }

  def minutes_to_allow_appointment
    if Rails.env.development?
      1.minutes.from_now.getutc
    else
      10.minutes.from_now.getutc
    end
  end

  def calculate_sales_tax
    raise "Sales tax cannot be calculated until tire quantity is set on the order." if self.tire_quantity.to_f < 1
    raise "Sales tax cannot be calculated unless a tire listing is chosen." if self.tire_listing.nil?
    raise "Sales tax cannot be calculated unless a tire listing has a price." if self.tire_listing.price.to_f <= 0

    self.tire_ea_price = self.tire_listing.price

    store_address = TaxCloud::Address.new(
      :address1 => self.tire_store.address1, 
      #:address2 => self.tire_store.address2, 
      :city => self.tire_store.city, :state => self.tire_store.state, :zip5 => self.tire_store.zipcode)

    self.transaction = TaxCloud::Transaction.new(
      :customer_id => self.tire_store.id, 
      :cart_id => (self.new_record? ? "1" : "#{self.id}"), 
      :order_id => (self.new_record? ? "1" : "#{self.id}"), 
      :origin => store_address, 
      :destination => store_address)

    self.transaction.cart_items << TaxCloud::CartItem.new(:index => 0, :item_id => self.tire_listing_id, 
      :tic => TaxCloud::TaxCodes::GENERAL, 
      :price => tire_ea_price.to_f, 
      :quantity => self.tire_quantity) unless tire_ea_price.to_f == 0.0

    self.transaction.cart_items << TaxCloud::CartItem.new(:index => 1, :item_id => "#{self.tire_listing_id}-1", 
      :tic => 10040, # 10040 is Installation Fees
      :price => tire_ea_install_price_labor.to_f, # tire_ea_install_price.to_f,
      :quantity => self.tire_quantity) unless tire_ea_install_price_labor.to_f == 0.0

    self.transaction.cart_items << TaxCloud::CartItem.new(:index => 2, :item_id => "#{self.tire_listing_id}-2", 
      :tic => 93101, # 10010 is "Computers, Electronics, and Appliances Digital Products Other/Miscellaneous"
      :price => th_user_fee.to_f, 
      :quantity => 1) unless th_user_fee.to_f == 0.0

    self.transaction.cart_items << TaxCloud::CartItem.new(:index => 3, :item_id => "#{self.tire_listing_id}-3", 
      :tic => TaxCloud::TaxCodes::GENERAL,
      :price => tire_ea_install_price_parts.to_f, 
      :quantity => self.tire_quantity) unless tire_ea_install_price_parts.to_f == 0.0

  	begin
      if Rails.env.development? && false
        self.sales_tax_collected = 0.0
        self.th_sales_tax_collected = 0.0

        self.sales_tax_collected += Money.new(52.22 * 100.0)
        self.sales_tax_on_tires = Money.new(52.22 * 100.0)

        self.sales_tax_collected += Money.new(3.60 * 100.0)
        self.sales_tax_on_installation = Money.new(3.60 * 100.0)

        self.th_sales_tax_collected += Money.new(1.57 * 100.0)
      else
    		self.lookup = self.transaction.lookup
    		self.sales_tax_collected = 0.0
    		self.th_sales_tax_collected = 0.0
    		self.lookup.cart_items.each do |c|
    			if c.cart_item_index == 0
    				self.sales_tax_collected += Money.new(c.tax_amount * 100.0)
            self.sales_tax_on_tires = Money.new(c.tax_amount * 100.0)
          elsif c.cart_item_index == 1
            self.sales_tax_collected += Money.new(c.tax_amount * 100.0)
            self.sales_tax_on_installation += Money.new(c.tax_amount * 100.0)
            self.sales_tax_on_install_labor = Money.new(c.tax_amount * 100.0).to_f
    			elsif c.cart_item_index == 2
    				self.th_sales_tax_collected += Money.new(c.tax_amount * 100.0)
          elsif c.cart_item_index == 3
            self.sales_tax_collected += Money.new(c.tax_amount * 100.0)
            self.sales_tax_on_installation += Money.new(c.tax_amount * 100.0)
            self.sales_tax_on_install_parts = Money.new(c.tax_amount * 100.0)
    			end
    		end
      end
  		##self.self.
  	rescue Exception => e 
      puts "Exception: #{e.to_s}"
      puts e.backtrace
  		self.errors.add("Sales Tax Calculation Error", e.message)
  		self.sales_tax_collected = 0.0
  	end
  end

  def total_retained_by_store
    Money.new(total_order_price * 100) - total_application_fee_money
  end

  def total_application_fee
    self.th_processing_fee.cents + self.th_user_fee.cents + self.th_sales_tax_collected.cents
  end

  def total_application_fee_money
    Money.new(self.th_processing_fee.cents + self.th_user_fee.cents + self.th_sales_tax_collected.cents)
  end

  def can_do_ecomm
    if self.tire_listing
      return self.tire_listing.can_do_ecomm?
    else
      return false
    end
  end

  def has_been_paid_for
    if self.stripe_charge_token.blank?
      return false 
    else
      return true 
    end
  end

  def my_buyer_email
    if Rails.env.production? || Rails.env.staging?
      return self.buyer_email
    else
      return system_process_completion_email_address()
    end
  end

  def my_seller_email
    if Rails.env.production? || Rails.env.staging?
      return self.tire_store.contact_email
    else
      return system_process_completion_email_address()
    end
  end

  def my_seller_phone
    if Rails.env.production?
      return tire_store.text_phone
    else
      return "7705303607"
    end
  end

  def my_buyer_phone
    if Rails.env.production?
      return self.buyer_phone
    else
      return "7705303607"
    end
  end

  def total_tire_price
  	raise "Total tire price cannot be calculated until tire quantity is set on the order." if self.tire_quantity.to_f < 1
  	raise "Total tire price cannot be calculated until price is set on the tire." if self.tire_ea_price.to_f < 1

  	self.tot_tire_price = self.tire_quantity.to_f * self.tire_ea_price.to_f
  	tot_tire_price
  end

  def total_install_price
  	raise "Total install price cannot be calculated until tire quantity is set on the order." if self.tire_quantity.to_f < 1

  	self.tot_install_price = self.tire_quantity.to_f * self.tire_ea_install_price.to_f

  	self.tot_install_price
  end

  def total_install_price_labor
    return self.tire_quantity.to_f * self.tire_ea_install_price_labor.to_f
  end

  def total_install_price_parts
    return self.tire_quantity.to_f * self.tire_ea_install_price_parts.to_f
  end

  def total_order_price
  	self.tot_order_price = self.sales_tax_collected.to_f + self.total_tire_price.to_f + self.total_install_price.to_f + self.th_user_fee.to_f + self.th_sales_tax_collected.to_f
  	tot_order_price
  end

  def calculate_user_fee
  	raise "User fee cannot be calculated until tire quantity is set on the order." if self.tire_quantity.to_f < 1
  	self.tire_ea_price = self.tire_listing.price
  	self.th_user_fee = (self.total_tire_price.to_f) * ($th_user_fee_percent / 100.0)
  end

  def calculate_processing_fee
  	raise "Processing fee cannot be calculated until tire quantity is set on the order." if self.tire_quantity.to_f < 1
  	self.th_processing_fee = self.total_order_price.to_f * ($th_processing_fee_percent / 100.0)
  end

  def calculate_transfer_amount
  	self.transfer_amount = self.total_tire_price.to_f + self.total_install_price.to_f + self.sales_tax_collected.to_f - self.th_processing_fee.to_f
  end

  def calculate_install_fee
    raise "Install fee cannot be calculated until tire quantity is set on the order." if self.tire_quantity.to_f < 1
    if self.tire_listing.includes_mounting?
      self.tire_ea_install_price = 0.00
    else
      self.tire_ea_install_price = self.tire_listing.get_install_price
      self.tire_ea_install_price_parts = self.tire_listing.get_install_price_parts
      self.tire_ea_install_price_labor = self.tire_listing.get_install_price_labor
    end
  end

  def tire_description
    if self.tire_listing.nil?
      nil 
    else
      self.tire_listing.cc_short_description
    end
  end

  def formatted_phone
    number_to_phone(buyer_phone.gsub(/\D/, ''))
  end

  def send_successfully_billed_buyer_email(minutes_to_wait=nil)
    if minutes_to_wait.nil?
      BillingMailer.successfully_billed_buyer(self, my_buyer_email).deliver
    elsif minutes_to_wait == 0
      BillingMailer.delay.successfully_billed_buyer(self.my_buyer_email)
    else
      BillingMailer.delay(run_at: minutes_to_wait).successfully_billed_buyer(self, my_buyer_email)
    end
  end

  def send_successfully_billed_seller_email(minutes_to_wait=nil)
    if minutes_to_wait.nil?
      BillingMailer.successfully_billed_seller(self, my_seller_email).deliver
    elsif minutes_to_wait == 0
      BillingMailer.delay.successfully_billed_seller(self, my_seller_email)
    else
      BillingMailer.delay(run_at: minutes_to_wait).successfully_billed_seller(self, my_seller_email)
    end
  end

  def send_successfully_refunded_buyer_email(msg)
    BillingMailer.successfully_refunded_buyer(self, my_buyer_email, msg).deliver
  end

  def send_successfully_refunded_seller_email(msg)
    BillingMailer.successfully_refunded_seller(self, my_seller_email, msg).deliver
  end

  def send_error_notifications(msg)
    text_msg = SystemProblemMailer.system_problem_text(msg)
    ts = TextSender.new()
    # ts.send_text("7705303607", text_msg.body.to_s)

    if true
      SystemProblemMailer.delay.system_problem(msg.gsub(/\\n/, '<br /><br />'))
    else
      SystemProblemMailer.system_problem(msg.gsub(/\\n/, '<br /><br />')).deliver
    end
  end

  def reverse_transfer_money_to_store
    if !self.stripe_reversal_transfer_token.blank?
      send_error_notifications("Fund transfer reversal problem! - order #{self.id} already has a transfer reversal token???")
    else
      begin
        @orig_transfer = Stripe::Transfer.retrieve(self.stripe_transfer_token)
        @reversal = @orig_transfer.reversals.create

        self.stripe_reversal_transfer_token = @transfer.id 
        self.save
      rescue Exception => e 
        msg = "Cancel Order number: #{self.id} is supposed to reverse transfer money from tire store #{self.tire_store.name}/#{self.tire_store.id}, but the transfer reversal failed for reason: #{e.to_s}."
        self.send_error_notifications(msg)
      end
    end
  end

  def transfer_money_to_store
    puts "*** TRANSFER MONEY TO STORE ***"
  	@amount_to_transfer = self.transfer_amount.cents
  	if self.status == :billed
  		if !self.stripe_transfer_token.blank?
  			send_error_notifications("Fund transfer problem! - order #{self.id} has a ready_for_billing status but also has a transfer token already???")
  		else
  			begin
	  			@transfer = Stripe::Transfer.create(
	  				:amount => @amount_to_transfer,
	  				:currency => "usd",
	  				:recipient => self.tire_store.stripe_recipient_id,
            ##:destination => self.tire_store.stripe_recipient_id,
            :source_transaction => self.stripe_charge_token,
	  				:description => "Order # #{self.id}-#{self.tire_quantity} #{self.tire_listing.cc_short_description}",
	  				:statement_descriptor => "Order # #{self.id}-#{self.tire_quantity} #{self.tire_listing.cc_short_description}".truncate(22),
	  				:metadata => {
	  					:order => self.id,
	  					:buyer_name => self.buyer_name,
	  					:buyer_email => self.buyer_email,
	  					:buyer_phone => self.buyer_phone,
	  					:tire_price => total_tire_price,
	  					:install_price => total_install_price,
	  					:sales_tax_collected => sales_tax_collected.to_f,
	  					:th_processing_fee => -1.0 * th_processing_fee.to_f
	  				}
	  			)

          # we're going to wait 10 (configurable) minutes to give the user time to create
          # an appointment.
          # BillingMailer.delay(run_at: self.minutes_to_allow_appointment).successful_funds_transfer(self)
          # Since we get appt before billing, this can be done immediately
          BillingMailer.delay.successful_funds_transfer(self)

	  			self.stripe_transfer_token = @transfer.id 
	  			self.save
	  		rescue Exception => e 
    			msg = "Order number: #{self.id} is supposed to transfer money to tire store #{self.tire_store.name}/#{self.tire_store.id}, but the transfer failed for reason: #{e.to_s}."
    			self.send_error_notifications(msg)
	  		end
  		end
  	else
    	msg = "Order number: #{self.id} is supposed to transfer money to tire store #{self.tire_store.name}/#{self.tire_store.id}, but status is #{self.status} and not :billed"
    	self.send_error_notifications(msg)
  	end
  end

  def total_order_price_in_cents
  	(self.total_order_price * 100).to_i
  end

  def cancel_transfer(msg)

    raise "Not implemented"

    if self.status <= :billed
      if false && self.stripe_transfer_token.blank?
        send_error_notifications("Tried to cancel transfer for order # #{self.id} - it has no original transfer token to cancel.")
      else
        if self.transfer_has_been_canceled
          msg = "Order::cancel_transfer - Order #{self.id} is supposed to have the transfer refunded but it has the transfer_has_been_canceled flag as TRUE"
          self.send_error_notifications(msg)
        else
          begin
            # 05/28/15 ksi Apparently transfer cancellations will fail...we only need to call
            # Refund, which is done in refund_order.  So we won't do this here.
            if false
              tr = Stripe::Transfer.retrieve(self.stripe_transfer_token)
              tr.cancel
            else
              puts "Transferring money back from store"
              reverse_transfer_money_to_store
            end

            self.transfer_has_been_canceled = true 
            save()
          rescue Exception => e 
            send_error_notifications("Error in cancel_transfer for order #{self.id} - #{e.to_s} - #{e.backtrace.join('\n')}")   
          end
        end
      end
    else
      msg = "Order::cancel_transfer - Order #{self.id} is supposed to have the transfer refunded but status is #{self.status}"
      self.send_error_notifications(msg)      
    end
  end

  def send_successfully_billed_seller_text
    text_msg = BillingMailer.successfully_billed_seller_text(self)
    ts = TextSender.new()
    ts.send_text(my_seller_phone.gsub(/\D/, ''), text_msg.body.to_s)
  end

  def send_successfully_billed_buyer_text
    # This one is written, but not going to do anything for now.  I don't think it makes
    # sense to send a text message to the seller when an order is billed since we let
    # them know when funds are transferred
    if false
      text_msg = BillingMailer.successfully_billed_buyer_text(self)
      ts = TextSender.new()
      ts.send_text(my_buyer_phone.gsub(/\D/, ''), text_msg.body.to_s)
    end
  end

  def eligible_for_refund?
    if self.status <= :billed
      if self.stripe_refund_token.blank?
        return true 
      else
        return false 
      end
    else
      return false
    end
  end

  def refund_order(msg)
  	if self.status <= :billed
    	if !self.stripe_charge_token.blank?
    		begin
    			@charge = Stripe::Charge.retrieve(self.stripe_charge_token)
          @refund = @charge.refunds.create 
          if @refund
            send_successfully_refunded_buyer_email(msg)
            send_successfully_refunded_seller_email(msg)

            # cancel sales tax transaction
            t = TaxCloud::Transaction.new
            t.order_id = self.id
            t.returned

            # cancel_transfer(msg)

            self.stripe_refund_token = @refund.id
            self.status = order_status_array[:refunded]

            self.refund_reason = msg 

            save

            return true
          else
            send_error_notifications("Tried to create a refund for order # #{self.id} - got a nil refund from Stripe?")
            self.refund_fail_message = "System error: refunding order on Stripe failed"
            save
            return false
          end
    		rescue Exception => e
	    		send_error_notifications("Error in refund_order for order #{self.id} - #{e.to_s} - #{e.backtrace.join('\n')}")
          self.refund_fail_message = "System error: refunding order on Stripe failed"
          self.save
          return false
    		end
    	else
    		msg = "Order number: #{self.id} is supposed to be refunded (for reason #{msg}), but status is #{self.status} and not :billed"
    		self.send_error_notifications(msg)
        self.refund_fail_message = "Order status of #{self.status} is not eligible for refund."
        self.save
        return false
    	end
  	else
    	msg = "Order number: #{self.id} is supposed to be refunded (for reason #{msg}), but status is #{self.status} and not :billed"
    	self.send_error_notifications(msg)
      self.refund_fail_message = "Order status of #{self.status} is not eligible for refund."
      self.save
      return false
  	end
  end

  def bill_order
    if self.status == :ready_for_billing
    	# check to make sure all else is good
    	if !self.stripe_charge_token.blank?
    		# error condition - we should not have a charge token for this status
    		send_error_notifications("Billing problem! - order #{self.id} has a ready_for_billing status but also has a charge token???")
    	else
	    	begin
	    		@customer = Stripe::Customer.retrieve(self.stripe_buyer_customer_token)
	    		if @customer 
            if false
              ## this is the old way
  	    			@charge = Stripe::Charge.create(
  	    				:amount => total_order_price_in_cents,
  	    				:currency => "usd",
  	    				:customer => self.stripe_buyer_customer_token,
  	    				##### :card => self.stripe_buyer_customer_cc_token,
                :source => self.stripe_buyer_customer_cc_token,
  	    				:description => "TreadHunter - #{self.tire_quantity} #{self.tire_listing.cc_short_description}",
  	    				:metadata => {"tire_store_id" => "#{self.tire_listing.tire_store_id}",
  	    								"tire_listing_id" => "#{self.tire_listing_id}",
  	    								"buyer_name" => "#{self.buyer_name}",
  	    								"buyer_phone" => "#{self.buyer_phone}",
  	    								"buyer_email" => "#{self.buyer_email}"},
  	    				:capture => true,
  	    				##### :statement_description => "TreadHunter-#{self.tire_quantity} #{self.tire_listing.tire_manufacturer_name}".truncate(22),
                :statement_descriptor => "TreadHunter-#{self.tire_quantity} #{self.tire_listing.tire_manufacturer_name}".truncate(22),
  	    				:receipt_email => self.buyer_email 
	    				)
    					if @charge.failure_code.nil?
    						if self.tire_store.send_text == true
                  send_successfully_billed_seller_text
    						end

    						# notify the buyer of the successful charge
                if self.notify_buyer_with_text == true
                  send_successfully_billed_buyer_text
                end

                # we're going to wait 10 (configurable) minutes to give the user time to create
                # an appointment.
                BillingMailer.delay(run_at: self.minutes_to_allow_appointment).successfully_billed_buyer(self)
                #BillingMailer.delay.successfully_billed_buyer(self)

    						# This one is not written yet, not sure we need to 
    						# notify the seller of a successful charge since
    						# we'll let them know of the transfer
    						# BillingMailer.delay.successfully_billed_seller(self)

    						# update status
    						self.stripe_charge_token = @charge.id
    						self.status = order_status_array[:billed]
    						save

    						# now transfer money to tire store
    						transfer_money_to_store()

    						save
              else
                send_error_notifications("Billing problem! - Tried to create a charge for order #{self.id}, got an error: #{@charge.failure_message}")
              end
            else
              # complete the sales tax piece
              self.calculate_sales_tax
              self.transaction.order_id = self.id 
              self.transaction.authorized_with_capture

              @charge = Stripe::Charge.create(
                  :amount => total_order_price_in_cents,
                  :currency => "usd",
                  :customer => self.stripe_buyer_customer_token,
                  ##### :card => self.stripe_buyer_customer_cc_token,
                  :source => self.stripe_buyer_customer_cc_token,
                  :description => "TreadHunter - #{self.tire_quantity} #{self.tire_listing.cc_short_description}",
                  :metadata => {"tire_store_id" => "#{self.tire_listing.tire_store_id}",
                          "tire_listing_id" => "#{self.tire_listing_id}",
                          "buyer_name" => "#{self.buyer_name}",
                          "buyer_phone" => "#{self.buyer_phone}",
                          "buyer_email" => "#{self.buyer_email}",
                          "Tires" => "#{self.tot_tire_price}",
                          "Installation" => "#{self.tot_install_price.to_money}",
                          "Sales Tax on Tires" => "#{self.sales_tax_on_tires.to_money}",
                          "Sales Tax on Install" => "#{self.sales_tax_on_installation.to_money}",
                          "TH consumer fee" => "#{self.th_user_fee.to_money}",
                          "Sales tax on TH consumer fee" => "#{self.th_sales_tax_collected.to_money}",
                          "Total Consumer Charge" => "#{total_order_price.to_money}",
                          "---------------------" => "--------------------",
                          "TH processing fee" => "- #{self.th_processing_fee.to_money}",
                          #"Tax on TH processing fee" => "- #{self.th_processing_fee.to_money}",
                          "Total TH application fee" => "- #{self.total_application_fee.to_money}"
                          #"Total transfer to store" => "#{total_order_price - self.th_processing_fee}"
                          },
                  :capture => true,
                  :application_fee => total_application_fee,
                  :destination => self.tire_store.stripe_account_id,
                  ####:receipt_number => self.id,
                  ##### :statement_description => "TreadHunter-#{self.tire_quantity} #{self.tire_listing.tire_manufacturer_name}".truncate(22),
                  :statement_descriptor => "TreadHunter-#{self.tire_quantity} #{self.tire_listing.tire_manufacturer_name}".truncate(22),
                  :receipt_email => self.buyer_email 
                  )
              if @charge.nil?
                send_error_notifications("Billing problem! - Tried to create a charge for order #{self.id}, but it came back nil.")
              elsif @charge.failure_code.nil?
                if self.tire_store.send_text == true
                  send_successfully_billed_seller_text
                end

                # notify the buyer of the successful charge
                if self.notify_buyer_with_text == true
                  send_successfully_billed_buyer_text
                end

                # we're going to wait 10 (configurable) minutes to give the user time to create
                # an appointment.
                #send_successfully_billed_buyer_email(self.minutes_to_allow_appointment)
                # 8/11 No longer need to way since appt created first
                send_successfully_billed_buyer_email(0)

                #send_successfully_billed_seller_email(self.minutes_to_allow_appointment)
                send_successfully_billed_seller_email(0)

                # update status
                self.stripe_charge_token = @charge.id
                self.status = order_status_array[:billed]
                save
              else
                send_error_notifications("Billing problem! - Tried to create a charge for order #{self.id}, got an error (#{@charge.failure_code}: #{@charge.failure_message}")
              end
  					end
	    		else
	    			send_error_notifications("Unable to retrieve customer with token #{self.stripe_buyer_customer_token} for order #{self.id}.")
	    		end
	    	rescue Exception => e 
	    		send_error_notifications("Error in bill_order for order #{self.id} - #{e.to_s} - #{e.backtrace.join('\n')}")
	    		add_failed_billing_attempt
	    		self.status = order_status_array[:billing_failed]
	    		save
	    		BillingMailer.delay.failed_to_bill_buyer(self, e.to_s)
	    		BillingMailer.delay.failed_to_bill_seller(self, e.to_s)
	    	end
	    end
    else
    	msg = "Order::bill_order was called for order number: #{self.id}, but status is #{self.status}"
    	self.send_error_notifications(msg)
    end
  end

  def initialize_test_data
  	t = TireStore.find_by_name('Midtown Tire Sugarloaf')
  	self.tire_listing_id = TireListing.find_by_tire_store_id_and_is_new_and_includes_mounting(t.id, true, false).id
  	self.tire_quantity = 4
  	self.calculate_total_order
  end

  def calculate_total_order
  	self.calculate_install_fee
  	self.calculate_user_fee
  	self.calculate_sales_tax

  	self.calculate_processing_fee

  	self.calculate_transfer_amount
  end

  def breakout_sales_tax
    if sales_tax_on_tires == 0.00 && sales_tax_on_installation == 0.00 && sales_tax_collected != 0.00
      return false
    else
      return true
    end
  end

  def sales_tax_on_tires
    if self.stripe_properties['sales_tax_on_tires'].blank?
      return 0.00
    else
      begin
        return self.stripe_properties['sales_tax_on_tires'].to_money
      rescue
        return 0.00
      end
    end
  end

  def tire_ea_install_price_parts=(val)
    if val.blank?
      self.destroy_key(:stripe_properties, :tire_ea_install_price_parts)
    else
      self.stripe_properties['tire_ea_install_price_parts'] = val
    end
  end

  def tire_ea_install_price_parts
    if self.stripe_properties['tire_ea_install_price_parts'].blank?
      return 0.00
    else
      begin
        return self.stripe_properties['tire_ea_install_price_parts'].to_money
      rescue
        return 0.00
      end
    end
  end

  def tire_ea_install_price_labor=(val)
    if val.blank?
      self.destroy_key(:stripe_properties, :tire_ea_install_price_labor)
    else
      self.stripe_properties['tire_ea_install_price_labor'] = val
    end
  end

  def tire_ea_install_price_labor
    if self.stripe_properties['tire_ea_install_price_labor'].blank?
      return 0.00
    else
      begin
        return self.stripe_properties['tire_ea_install_price_labor'].to_money
      rescue
        return 0.00
      end
    end
  end

  def sales_tax_on_install_parts=(sales_tax)
    if sales_tax.blank?
      self.destroy_key(:stripe_properties, :sales_tax_on_install_parts)
    else
      self.stripe_properties['sales_tax_on_install_parts'] = sales_tax
    end
  end

  def sales_tax_on_install_parts
    if self.stripe_properties['sales_tax_on_install_parts'].blank?
      return 0.00
    else
      begin
        return self.stripe_properties['sales_tax_on_install_parts'].to_money
      rescue
        return 0.00
      end
    end
  end

  def sales_tax_on_install_labor=(sales_tax)
    if sales_tax.blank?
      self.destroy_key(:stripe_properties, :sales_tax_on_install_labor)
    else
      self.stripe_properties['sales_tax_on_install_labor'] = sales_tax
    end
  end

  def sales_tax_on_install_labor
    if self.stripe_properties['sales_tax_on_install_labor'].blank?
      return 0.00
    else
      begin
        return self.stripe_properties['sales_tax_on_install_labor'].to_money
      rescue
        return 0.00
      end
    end
  end

  def tire_ea_install_price_labor
    if self.stripe_properties['tire_ea_install_price_labor'].blank?
      return (0.00).to_money
    else
      begin
        return self.stripe_properties['tire_ea_install_price_labor'].to_money
      rescue
        return (0.00).to_money
      end
    end
  end

  def sales_tax_on_tires=(sales_tax)
    if sales_tax.blank?
      self.destroy_key(:stripe_properties, :sales_tax_on_tires)
    else
      self.stripe_properties['sales_tax_on_tires'] = sales_tax
    end
  end

  def sales_tax_on_installation
    if self.stripe_properties['sales_tax_on_installation'].blank?
      return (0.00).to_money
    else
      begin
        return self.stripe_properties['sales_tax_on_installation'].to_money
      rescue
        return (0.00).to_money
      end
    end
  end

  def sales_tax_on_installation=(sales_tax)
    if sales_tax.blank?
      self.destroy_key(:stripe_properties, :sales_tax_on_installation)
    else
      self.stripe_properties['sales_tax_on_installation'] = sales_tax
    end
  end

  def has_sent_funds_transfer_email
    begin
      bHasSent = self.stripe_properties['has_sent_funds_transfer_email'].to_s.to_bool
      return bHasSent
    rescue
      return false
    end
  end

  def has_sent_funds_transfer_email=(bHasSent)
    sHasSent = bHasSent.to_s
    if sHasSent.blank?
      self.destroy_key(:stripe_properties, :has_sent_funds_transfer_email)
    else
      begin
        self.stripe_properties['has_sent_funds_transfer_email'] = sHasSent
      rescue
        self.stripe_properties['has_sent_funds_transfer_email'] = false
      end
    end
  end

  def has_sent_successful_charge_email
    begin
      bHasSent = self.stripe_properties['has_sent_successful_charge_email'].to_s.to_bool
      return bHasSent
    rescue
      return false
    end
  end

  def has_sent_successful_charge_email=(bHasSent)
    sHasSent = bHasSent.to_s
    if sHasSent.blank?
      self.destroy_key(:stripe_properties, :has_sent_successful_charge_email)
    else
      begin
        self.stripe_properties['has_sent_successful_charge_email'] = sHasSent
      rescue
        self.stripe_properties['has_sent_successful_charge_email'] = false
      end
    end
  end

  def notify_buyer_with_text
    begin
	    bNotify = self.stripe_properties['notify_buyer_with_text'].to_s.to_bool
    	return bNotify
    rescue
    	return false
    end
  end

  def notify_buyer_with_text=(bNotify)
  	sNotify = bNotify.to_s
    if sNotify.blank?
		  self.destroy_key(:stripe_properties, :notify_buyer_with_text)
    else
    	begin
			self.stripe_properties['notify_buyer_with_text'] = sNotify
		rescue
			self.stripe_properties['notify_buyer_with_text'] = false
		end
    end
  end

  def transfer_has_been_canceled
    begin
      bCanceled = self.stripe_properties['transfer_has_been_canceled'].to_s.to_bool
      return bCanceled
    rescue
      return false
    end
  end

  def transfer_has_been_canceled=(bCanceled)
    sCanceled = bCanceled.to_s
    if sCanceled.blank?
      self.destroy_key(:stripe_properties, :transfer_has_been_canceled)
    else
      begin
      self.stripe_properties['transfer_has_been_canceled'] = sCanceled
    rescue
      self.stripe_properties['transfer_has_been_canceled'] = false
    end
    end
  end

  def failed_billing_attempts
  	self.stripe_properties['failed_billing_attempts'].to_i
  end

  def failed_billing_attempts=(num_attempts)
    if num_attempts.blank?
      self.destroy_key(:stripe_properties, :failed_billing_attempts)
    else
      self.stripe_properties['failed_billing_attempts'] = num_attempts.to_s
    end
  end  

  def add_failed_billing_attempt
  	num_attempts = self.failed_billing_attempts()
  	self.failed_billing_attempts = num_attempts + 1
  end

  def stripe_reversal_transfer_token
    self.stripe_properties['stripe_reversal_transfer_token']
  end

  def stripe_reversal_transfer_token=(transfer_token)
    if transfer_token.blank?
      self.destroy_key(:stripe_properties, :stripe_reversal_transfer_token)
    else
      self.stripe_properties['stripe_reversal_transfer_token'] = transfer_token
    end
  end

  def stripe_transfer_token
    self.stripe_properties['stripe_transfer_token']
  end

  def stripe_transfer_token=(transfer_token)
    if transfer_token.blank?
      self.destroy_key(:stripe_properties, :stripe_transfer_token)
    else
      self.stripe_properties['stripe_transfer_token'] = transfer_token
    end
  end

  def stripe_refund_token
    self.stripe_properties['stripe_refund_token']
  end

  def stripe_refund_token=(refund_token)
    if refund_token.blank?
      self.destroy_key(:stripe_properties, :stripe_refund_token)
    else
      self.stripe_properties['stripe_refund_token'] = refund_token
    end
  end  

  def stripe_charge_token
    self.stripe_properties['stripe_charge_token']
  end

  def stripe_charge_token=(charge_token)
    if charge_token.blank?
      self.destroy_key(:stripe_properties, :stripe_charge_token)
    else
      self.stripe_properties['stripe_charge_token'] = charge_token
    end
  end  

  def stripe_buyer_customer_token
    self.stripe_properties['stripe_buyer_customer_token']
  end

  def stripe_buyer_customer_token=(customer_token)
    if customer_token.blank?
      self.destroy_key(:stripe_properties, :stripe_buyer_customer_token)
    else
      self.stripe_properties['stripe_buyer_customer_token'] = customer_token
    end
  end  

  def stripe_buyer_customer_cc_token
    self.stripe_properties['stripe_buyer_customer_cc_token']
  end

  def stripe_buyer_customer_cc_token=(customer_cc_token)
    if customer_id.blank?
      self.destroy_key(:stripe_properties, :stripe_buyer_customer_cc_token)
    else
      self.stripe_properties['stripe_buyer_customer_cc_token'] = customer_cc_token
    end
  end

  def refund_reason
    self.stripe_properties['refund_reason']
  end

  def refund_reason=(reason)
    if reason.blank?
      self.destroy_key(:stripe_properties, :refund_reason)
    else
      self.stripe_properties['refund_reason'] = reason
    end
  end

  def refund_fail_message
    self.stripe_properties['refund_fail_message']
  end

  def refund_fail_message=(msg)
    if msg.blank?
      self.destroy_key(:stripe_properties, :refund_fail_message)
    else
      self.stripe_properties['refund_fail_message'] = msg 
    end
  end

  def uuid
  	self.stripe_properties['uuid']
  end

  def uuid=(new_uuid)
  	if new_uuid.blank?
  		self.destroy_key(:stripe_properties, :uuid)
  	else
  		self.stripe_properties['uuid'] = new_uuid
  	end
  end

  def sales_tax_collected_money
    return sales_tax_collected.to_f
  end

  def sales_tax_collected_money_formatted
    return number_to_currency sales_tax_collected
  end

  def total_install_price_labor_money
    return number_to_currency total_install_price_labor
  end

  def total_install_price_parts_money
    return number_to_currency total_install_price_parts
  end

  def sales_tax_on_tires_money
    return number_to_currency sales_tax_on_tires
  end

  def sales_tax_on_install_money
    return number_to_currency sales_tax_on_installation
  end

  def sales_tax_on_install_parts_money
    return number_to_currency self.sales_tax_on_install_parts.to_money
  end

  def sales_tax_on_install_labor_money
    return number_to_currency self.sales_tax_on_install_labor.to_money
  end

  def th_processing_fee_money
    return th_processing_fee.to_f
  end

  def th_sales_tax_collected_money
    return number_to_currency th_sales_tax_collected
  end

  def th_user_fee_money
    return th_user_fee.to_f
  end

  def th_user_fee_money_formatted
    return number_to_currency th_user_fee
  end

  def transfer_amount_money
    return transfer_amount.to_f
  end

  def tire_ea_price_money
    return tire_ea_price.to_f
  end

  def total_order_price_money
    return number_to_currency total_order_price
  end

  def total_install_price_money
    return number_to_currency total_install_price 
  end

  def total_tire_price_money
    return number_to_currency total_tire_price
  end
end
