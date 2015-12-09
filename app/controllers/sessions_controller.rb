class SessionsController < ApplicationController
  include ApplicationHelper

  skip_before_filter :clear_return_path

  def new
  end

  def create
    user = User.find_by_email(params[:session][:email].downcase)
    return_to = session[:return_to]

    if user && user.authenticate(params[:session][:password])
      sign_in user

      if in_storefront?
        redirect_to '/'
      elsif return_to.nil? && return_to.to_s.length > 0
        redirect_back_or return_to
      elsif super_user?
        if return_to && (return_to.blank? || return_to == '/')
          redirect_to '/accounts'
        else
          redirect_back_or '/accounts'
        end
      elsif user.is_tireseller?
        if return_to && (return_to.blank? || return_to == '/')
          redirect_to '/myTreadHunter'
        else
          redirect_back_or '/myTreadHunter'
        end
      else
        redirect_to('/', :notice => "Successful login.")
      end
    else
      flash.now[:error] = 'Invalid email/password combination'
      render 'new'
    end
  end

  def mobile_create
    begin
      # 03/22/13 ksi Check to see if this is a user designated to use the beta site.
      # For example, the Apple store uses "demo@treadhunter.com", which we want to
      # go to the beta site so whatever they post isn't "live".  So we will do an
      # instant redirect for those users.
      decoded_email = token_decode(params[:base64_email]).downcase

      if beta_users.include?(decoded_email)
        redirect_to "http://beta.treadhunter.com#{request.original_fullpath}", :status => :moved_permanently
        return
      end

      user = User.find_by_email(decoded_email)
      if user
        if user.authenticate(token_decode(params[:base64_password]))
          user.set_mobile_token
          h = Hash.new
          h[:public_token] = user.public_mobile_token
          h[:server_override] = "#{request.protocol}#{request.host_with_port}/"
          h[:bcl] = true # for now, do not allow CL cross-posting for anyone... cl_blocked_users.include?(decoded_email)
          h[:tireseller] = user.is_tireseller? || user.is_super_user?
          if !user.account.nil?
            h[:account_id] = user.account.id
            h[:tire_store_id] = user.tire_store_id
          else
            h[:account_id] = -1
            h[:tire_store_id] = -1
          end
          render :json => h
        else
          render :file => "public/422.html", :status => :unauthorized
          return
        end
      else
        render :file => "public/422.html", :status => :not_found
        return
      end
    rescue Exception => e
      render :file => "public/422.html", :status => :internal_server_error
      return
    end
  end

  def destroy
  	sign_out
    redirect_to root_path, :alert => "User signed out." 
  end

end