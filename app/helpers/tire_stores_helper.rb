module TireStoresHelper
    #helper_method :valid_import_frequency

    def correct_ts_user
        if !current_user.nil?
            if !edit_access
                redirect_to root_path, :alert => "You do not have access to that page."
                return false
            end
        else
            redirect_to root_path, :alert => "You do not have access to that page."
            return false
        end
        return true
    end

    def has_create_access
    	bResult = true
    	if !super_user?
    		if current_user.nil? || !current_user.is_tireseller? || !current_user.is_admin?
    			bResult = false
    			redirect_to root_path, :alert => "You do not have access to that page."
    		end
    	end
    	bResult
    end

    def is_super_user
        if !super_user?
            redirect_to root_path, :alert => "You do not have access to that page."
        end            
    end

    def edit_access(tire_store=nil)
        if super_user?
            true
        else
            if @tire_store.nil?
                @tire_store = tire_store
            end
            if @tire_store.nil?
                @tire_store = TireStore.find_by_id(params[:id]) if params[:id]
                if @tire_store.nil?
                    @tire_store = TireStore.find_by_id(params[:tire_store_id]) if params[:tire_store_id]
                end
                if @tire_store.nil?
                    if !params[:tire_store].nil? && params[:tire_store]["id"]
                        tire_store_id = params[:tire_store]["id"]
                    else
                        tire_store_id = nil
                    end
                    @tire_store = TireStore.find_by_id(tire_store_id)
                end
                if @tire_store.nil? && !current_user.nil?
                    @tire_store = current_user.tire_store
                end
            end
            if @tire_store.nil?
                false
            elsif current_user.nil? || current_user.account_id != @tire_store.account_id
                false
            else
                true
            end
        end
    end

    def nl2br(s)
        s.gsub(/\n/, '<br>')
    end

    module SortOrder    
        SORT_BY_MANU_ASC = 1
        SORT_BY_MANU_DESC = 2
        SORT_BY_SIZE_ASC = 3
        SORT_BY_SIZE_DESC = 4
        SORT_BY_UPDATED_ASC = 5
        SORT_BY_UPDATED_DESC = 6
        SORT_BY_QTY_ASC = 7
        SORT_BY_QTY_DESC = 8
        SORT_BY_TYPE_ASC = 9
        SORT_BY_TYPE_DESC = 10
        SORT_BY_TREADLIFE_ASC = 11
        SORT_BY_TREADLIFE_DESC = 12
        SORT_BY_DISTANCE_ASC = 13
        SORT_BY_DISTANCE_DESC = 14
        SORT_BY_COST_PER_TIRE_ASC = 15
        SORT_BY_COST_PER_TIRE_DESC = 16
        SORT_BY_MODEL_NAME_ASC = 17
        SORT_BY_MODEL_NAME_DESC = 18
        SORT_BY_STORE_NAME_ASC = 19
        SORT_BY_STORE_NAME_DESC = 20
    end

    def valid_import_frequency
    [
      ['No auto import', 0],
      ['Every 30 Days', 30],
      ['Every 60 Days', 60],
      ['Every 90 Days', 90]
    ]
    end
end
