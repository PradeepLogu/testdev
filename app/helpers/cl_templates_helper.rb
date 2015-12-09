module ClTemplatesHelper
    def correct_user
        if !edit_access
            redirect_to root_path, :alert => "You do not have access to that page." #{}" #{current_user.nil?} #{params[:id]} #{current_user.account_id}"
        end
    end

    def has_create_access
    	bResult = true
    	if !super_user?
    		if current_user.nil? || !current_user.is_tireseller? || !current_user.is_admin?
    			bResult = false
    			redirect_to root_path, :alert => "You do not have access to that page." #{}" #{current_user.nil?} #{params[:id]} #{current_user.account_id}"
    		end
    	end
    	bResult
    end

    def edit_access
        if super_user?
            true
        else
            @tire_store = TireStore.find(params[:tire_store_id])
            if current_user.nil? || current_user.account_id != @tire_store.account_id || 
                !@tire_store.account.can_use_mobile?
                false
            else
                true
            end
        end
    end
end
