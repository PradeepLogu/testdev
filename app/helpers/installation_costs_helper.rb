module InstallationCostsHelper  
	def has_account_access
		if current_user.nil? || current_user.account.nil? || params[:tire_store_id].blank?
			redirect_to root_path, :alert => "This account does not have those privileges."
			return
		end
		@account_id = params[:account_id]
		@account = Account.find_by_id(@account_id)
		if @account.nil?
			@account = TireStore.find_by_id(params[:tire_store_id]).account 
		end
		if !super_user? && current_user && (current_user.account != @account.id)
			redirect_to root_path, :alert => "This account does not have those privileges."
		end
	end
end