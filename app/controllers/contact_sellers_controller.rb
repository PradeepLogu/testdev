class ContactSellersController < ApplicationController
  def new
    # id is required to deal with form
    @contact_seller = ContactSeller.new(:id => 1)
  end

  def create
    if !simple_captcha_valid?
      flash[:alert] = "Please enter the characters shown in the box."
      
      begin
        u = URI.parse(request.env["HTTP_REFERER"])
        if !u.query
          # no query string
          redirect_to (request.env["HTTP_REFERER"] + "?contact=true")
        else
          # we have a query string...see if we have a contact
          p = CGI.parse(u.query)
          if p["contact"].blank?
            redirect_to (request.env["HTTP_REFERER"] + "&contact=true")
          else
            redirect_to :back
          end
        end
      rescue Exception => e 
        redirect_to :back
      end

      return
    end

    @contact_seller = ContactSeller.new(params[:contact_seller])
    @contact_seller.remote_ip = ip
    if @contact_seller.save
      flash[:info] = "Email sent to seller."
      # now we have to go back to where we were
      begin
        redirect_to request.env["HTTP_REFERER"].gsub(/\?contact\=true/, '').gsub(/\&contact\=true/, '')
      rescue Exception => e 
        redirect_to :back
      end
      return
    else
      @err_msg = ""
      @contact_seller.errors.each do |a, b|
        @err_msg += "#{a} #{b} "
      end
      flash[:alert] = @err_msg
      
      begin
        u = URI.parse(request.env["HTTP_REFERER"])
        if !u.query
          # no query string
          redirect_to (request.env["HTTP_REFERER"] + "?contact=true")
        else
          # we have a query string...see if we have a contact
          p = CGI.parse(u.query)
          if p["contact"].blank?
            redirect_to (request.env["HTTP_REFERER"] + "&contact=true")
          else
            redirect_to :back
          end
        end
      rescue Exception => e 
        redirect_to :back
      end

      #render :nothing => true, :status => :fail
      return
    end
  end 

  def ip
    if !request.remote_ip.to_s.empty?
      request.remote_ip
    elsif !request.remote_addr.to_s.empty?
      request.remote_addr 
    elsif addr = @env['HTTP_X_FORWARDED_FOR']
      addr.split(',').last.strip 
    else
      @env['REMOTE_ADDR']
    end
  end
end