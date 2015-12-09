module TireListingsHelper  
    def correct_user
      if !current_user.nil?
      	if !super_user?
      		@tire_listing = TireListing.find(params[:id])
      		if current_user.nil? || current_user.account_id != @tire_listing.tire_store.account_id
         			redirect_to root_path, :alert => "You do not have access to that page."
        	end
        end
      end
    end

    def signed_in
    	if current_user.nil?       			
    		redirect_to root_path, :alert => "You do not have access to that page."
    	end
    end

    def has_posting_access
      if !current_user.nil?
        if !super_user? && (current_user.nil? || current_user.account.nil? || !current_user.account.can_post_listings?)
          redirect_to root_path, :alert => "This account does not have posting privileges."
        end
      end
    end

    def is_super_user
      if !super_user?
        redirect_to root_path, :alert => "You do not have access to that page."
      end
    end
end
