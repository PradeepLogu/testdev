
module TireSearchesHelper
	def correct_user
		if !edit_access
			redirect_to root_path, :alert => "You do not have access to that page." #{}" #{current_user.nil?} #{params[:id]} #{current_user.account_id}"
		end
    end

    def edit_access
        if super_user?
            true
        else
            @tire_search = TireSearch.find(params[:id])
            if current_user.nil? || current_user.id != @tire_search.user_id
                false
            else
                true
            end
        end
    end
end
