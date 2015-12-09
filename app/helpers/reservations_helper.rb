module ReservationsHelper
  def correct_user
  	if !super_user?
  		@reservation = Reservation.find_by_id(params[:id])
      if !@reservation.nil?
    		if current_user.nil? || 
    			(current_user.is_tireseller? && current_user.account_id !=
    					 @reservation.tire_listing.tire_store.account_id) ||
    			(current_user.is_tirebuyer? && current_user.id != @reservation.user_id)
       			redirect_to root_path, :alert => "You do not have access to that page." #{}" #{current_user.nil?} #{params[:id]} #{current_user.account_id}"
      		end
      	end
      end
  end

  def is_superuser
    if !super_user?
      redirect_to root_path, :alert => "You do not have access to that page."
    end
  end
end
