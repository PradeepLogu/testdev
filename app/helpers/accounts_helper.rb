module AccountsHelper
  
    def correct_user
    	if !super_user?
    		if current_user.nil? || current_user.account_id.to_s != params[:id]
       			redirect_to root_path, :alert => "You do not have access to that page. "#{current_user.nil?} correct_user "#{params[:id]} #{current_user.account_id}"
      		end
      	end
    end

    def signed_in
    	if current_user.nil?       			
    		redirect_to root_path, :alert => "You do not have access to that page. "#{current_user.nil?} signed_in"#{params[:id]} #{current_user.account_id}"
    	end
    end

    def is_super_user
      if !super_user?
        redirect_to root_path, :alert => "You do not have access to that page. "#{current_user.nil?} correct_user "#{params[:id]} #{current_user.account_id}"
      end
    end
end
