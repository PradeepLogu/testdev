class ContactUsController < ApplicationController
  def new
    # id is required to deal with form
    @contact_us = ContactUs.new(:id => 1)
  end

  def create
    @contact_us = ContactUs.new(params[:contact_us])
    @contact_us.remote_ip = ip
    if @contact_us.save
      redirect_to('/', :notice => "Email request was successfully sent.")
    else
      flash[:alert] = "You must fill all fields."
      render 'new'
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