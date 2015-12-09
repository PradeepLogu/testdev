class DevicesController < ApplicationController
	def register_device
		@device_token = params[:device_token]
		@platform = params[:platform]
		@user_token = params[:user_token]

		@user = User.find_by_mobile_token(token_decode(@user_token))
		@user = User.find_by_remember_token(token_decode(@user_token)) unless @user

		if @user
			@device = Device.find_by_token(@device_token)

			if @device.nil?
				@device = Device.new
				@device.token = @device_token
			end
			@device.user = @user
			@device.platform = @platform
			puts "Saving"
			@device.save
			puts "Done saving"
      		respond_to do |format|
				format.json { render json: "ok".to_json }
			end
		else
			puts "user not found"
			render :file => "public/422.html", :status => :internal_server_error
		end
	end

	def update_device
		@device_token = params[:device_token]
		@tire_store_id = params[:tire_store_id]
		@account_id = params[:account_id]
		@user_token = params[:user_token]
		@platform = params[:platform]

		@user = User.find_by_mobile_token(token_decode(@user_token))
		@user = User.find_by_remember_token(token_decode(@user_token)) unless @user

		if @user
			@device = Device.find_by_token_and_user_id(@device_token, @user.id)

			if @device
				@device.update_attribute(:account_id, @account_id)
				@device.update_attribute(:tire_store_id, @tire_store_id)
	      		respond_to do |format|
					format.json { render json: "ok".to_json }
				end
			else
				render :file => "public/422.html", :status => :internal_server_error
			end
		else
			render :file => "public/422.html", :status => :internal_server_error
		end
	end	
end
