class ReservationMailer < ActionMailer::Base
  default from: "mail@treadhunter.com"

  def tire_buyer_reservation(reservation)
  	@reservation = reservation
  	mail(:to => @reservation.buyer_email, subject: 'TreadHunter.com - Tire Reservation')
  end

  def tire_seller_reservation(reservation)
  	@reservation = reservation
  	mail(:to => @reservation.seller_email, subject: 'TreadHunter.com - Tire Reservation')
  end

  def tire_buyer_cancellation_by_buyer(reservation)
    @reservation = reservation
    mail(:to => @reservation.buyer_email, subject: 'TreadHunter.com - Tire Reservation Cancellation')
  end

  def tire_seller_cancellation_by_buyer(reservation)
    @reservation = reservation
    mail(:to => @reservation.buyer_email, subject: 'TreadHunter.com - Tire Reservation Cancellation')
  end

  def tire_buyer_cancellation_by_seller(reservation)
    @reservation = reservation
    mail(:to => @reservation.buyer_email, subject: 'TreadHunter.com - Tire Reservation Cancellation')
  end

  def tire_seller_cancellation_by_seller(reservation)
    @reservation = reservation
    mail(:to => @reservation.buyer_email, subject: 'TreadHunter.com - Tire Reservation Cancellation')
  end

  def tire_buyer_cancellation_by_system(reservation)
    @reservation = reservation
    mail(:to => @reservation.buyer_email, subject: 'TreadHunter.com - Tire Reservation Cancellation')
  end

  def tire_seller_cancellation_by_system(reservation)
    @reservation = reservation
    mail(:to => @reservation.seller_email, subject: 'TreadHunter.com - Tire Reservation Cancellation')
  end

  def tire_buyer_reservation_text(reservation)
    @reservation = reservation
    mail(:to => 'admin@treadhunter.com', subject: 'not used')
  end

  def tire_seller_reservation_text(reservation)
    @reservation = reservation
    mail(:to => 'admin@treadhunter.com', subject: 'not used')
  end
end
