module PromotionsHelper
	def has_promotion_access
		if !current_user || (!super_user? && !current_user.is_tireseller?)
			redirect_to root_path, :alert => "You do not have permission for this feature."
		end
	end
end
