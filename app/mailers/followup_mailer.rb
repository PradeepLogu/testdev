include MailHelper

class FollowupMailer < ActionMailer::Base
  TH_SURVEY_MISSING_EMAIL = "jbarker@treadhunter.com"

  # send customer care a notice  
  def survey_declined(account)
    @account = account
    if @account.tire_stores.size > 0
      @user = @account.users.first
      @tire_store = @account.tire_stores.first
    end

    if MailHelper.was_email_sent?(self, @account.id, @user.email)
      self.message = Mail::Message.new
      mail.perform_deliveries = false
      @abort = true
    else
      if !@tire_store.nil? && !@user.nil? && !@account.nil?
        @survey_url = @account.survey_url("http://#{ActionMailer::Base.default_url_options[:host]}")
        MailHelper.email_sent(self, @account.id, @user.email)
        
        mail(:to => @user.email,
              :bcc => customer_issue_email_address(),
              :from => 'mail@treadhunter.com',
              :subject => "Please help #{@user.name} from #{@account.name} complete the TreadHunter survey")
      else
        self.message = Mail::Message.new
        mail.perform_deliveries = false
        @abort = true
      end
    end
  end

  # send the customer a reminder
  def one_day_no_survey(account)
    @account = account
    if @account.tire_stores.size > 0
      @user = @account.users.first
      @tire_store = @account.tire_stores.first
    end

    if MailHelper.was_email_sent?(self, @account.id, @user.email)
      self.message = Mail::Message.new
      mail.perform_deliveries = false
      @abort = true
    else
      if !@tire_store.nil? && !@user.nil? && !@account.nil?
        @survey_url = @account.survey_url("http://#{ActionMailer::Base.default_url_options[:host]}")
        @decline_survey_url = "http://#{ActionMailer::Base.default_url_options[:host]}/pages/survey_declined?account_id=<%= @account.id %>"
        MailHelper.email_sent(self, @account.id, @user.email)
        
        mail(:to => @user.email,
              :bcc => customer_issue_email_address(),
              :from => 'mail@treadhunter.com',
              :subject => "Please complete the TreadHunter survey")
      else
        self.message = Mail::Message.new
        mail.perform_deliveries = false
        @abort = true
      end
    end
  end

  # send customer care a reminder
  def three_days_no_survey(account)
    @account = account
    if @account.tire_stores.size > 0
      @user = @account.users.first
      @tire_store = @account.tire_stores.first
    end

    if MailHelper.was_email_sent?(self, @account.id, TH_SURVEY_MISSING_EMAIL)
      self.message = Mail::Message.new
      mail.perform_deliveries = false
      @abort = true
    else
      if !@tire_store.nil? && !@user.nil? && !@account.nil?
        @survey_url = @account.survey_url("http://#{ActionMailer::Base.default_url_options[:host]}")
        MailHelper.email_sent(self, @account.id, TH_SURVEY_MISSING_EMAIL)
        
        mail(:to => "#{TH_SURVEY_MISSING_EMAIL}",
              :bcc => customer_issue_email_address(),
              :from => 'mail@treadhunter.com',
              :subject => "Please help #{@user.name} from #{@account.name} complete the TreadHunter survey")
      else
        self.message = Mail::Message.new
        mail.perform_deliveries = false
        @abort = true
      end
    end
  end

  # send customer care a reminder
  def seven_days_no_survey(account)
    @account = account
    if @account.tire_stores.size > 0
      @user = @account.users.first
      @tire_store = @account.tire_stores.first
    end

    if MailHelper.was_email_sent?(self, @account.id, TH_SURVEY_MISSING_EMAIL)
      self.message = Mail::Message.new
      mail.perform_deliveries = false
      @abort = true
    else
      if !@tire_store.nil? && !@user.nil? && !@account.nil?
        @survey_url = @account.survey_url("http://#{ActionMailer::Base.default_url_options[:host]}")
        MailHelper.email_sent(self, @account.id, TH_SURVEY_MISSING_EMAIL)
        
        mail(:to => "#{TH_SURVEY_MISSING_EMAIL}",
              :bcc => customer_issue_email_address(),
              :from => 'mail@treadhunter.com',
              :subject => "Please help #{@user.name} from #{@account.name} complete the TreadHunter survey")
      else
        self.message = Mail::Message.new
        mail.perform_deliveries = false
        @abort = true
      end
    end
  end

  # send customer care a reminder
  def fourteen_days_no_survey(account)
    @account = account
    if @account.tire_stores.size > 0
      @user = @account.users.first
      @tire_store = @account.tire_stores.first
    end

    if MailHelper.was_email_sent?(self, @account.id, TH_SURVEY_MISSING_EMAIL)
      self.message = Mail::Message.new
      mail.perform_deliveries = false
      @abort = true
    else
      if !@tire_store.nil? && !@user.nil? && !@account.nil?
        @survey_url = @account.survey_url("http://#{ActionMailer::Base.default_url_options[:host]}")
        MailHelper.email_sent(self, @account.id, TH_SURVEY_MISSING_EMAIL)
        
        mail(:to => "#{TH_SURVEY_MISSING_EMAIL}",
              :bcc => customer_issue_email_address(),
              :from => 'mail@treadhunter.com',
              :subject => "Please help #{@user.name} from #{@account.name} complete the TreadHunter survey")
      else
        self.message = Mail::Message.new
        mail.perform_deliveries = false
        @abort = true
      end
    end
  end

  def three_days_no_listings(user, tire_store)
    @user = user
    @tire_store = tire_store
    @abort = false
    
    if MailHelper.was_email_sent?(self, @tire_store.id, @user.email)
      self.message = Mail::Message.new
      mail.perform_deliveries = false
      @abort = true
    else
      if !@tire_store.nil? 
        @bulk_url = "http://#{ActionMailer::Base.default_url_options[:host]}/generic_tire_listings/new?tire_store_id=#{@tire_store.id}"
        @multiple_url = "http://#{ActionMailer::Base.default_url_options[:host]}/new_multiple?tire_store_id=#{@tire_store.id}"
        @TCI_url = "http://#{ActionMailer::Base.default_url_options[:host]}/tire_stores_distributors/edit?distributor_id=#{Distributor.find_by_distributor_name('Tire Centers, LLC').id}&tire_store_id=#{@tire_store.id}"
        MailHelper.email_sent(self, @tire_store.id, @user.email)
        
        mail(:to => @user.email,
              :bcc => customer_issue_email_address(),
              :from => 'mail@treadhunter.com',
              :subject => "Don't forget to list your tires!")
      else
        self.message = Mail::Message.new
        mail.perform_deliveries = false
        @abort = true
      end
    end
  end
  
  def ten_days_no_listings(user, tire_store)
    @user = user
    @tire_store = tire_store
    @abort = false
    
    if MailHelper.was_email_sent?(self, @tire_store.id, @user.email)
      self.message = Mail::Message.new
      mail.perform_deliveries = false
      @abort = true
    else
      if !@tire_store.nil? 
        @bulk_url = "http://#{ActionMailer::Base.default_url_options[:host]}/generic_tire_listings/new?tire_store_id=#{@tire_store.id}"
        @multiple_url = "http://#{ActionMailer::Base.default_url_options[:host]}/new_multiple?tire_store_id=#{@tire_store.id}"
        @TCI_url = "http://#{ActionMailer::Base.default_url_options[:host]}/tire_stores_distributors/edit?distributor_id=#{Distributor.find_by_distributor_name('Tire Centers, LLC').id}&tire_store_id=#{@tire_store.id}"
        MailHelper.email_sent(self, @tire_store.id, @user.email)
        
        mail(:to => @user.email,
              :bcc => customer_issue_email_address(),
              :from => 'mail@treadhunter.com',
              :subject => "Don't forget to list your tires!")
      else
        self.message = Mail::Message.new
        mail.perform_deliveries = false
        @abort = true
      end
    end
  end
  
  def three_weeks_no_listings(user, tire_store)
    @user = user
    @tire_store = tire_store
    @abort = false
    
    if MailHelper.was_email_sent?(self, @tire_store.id, @user.email)
      self.message = Mail::Message.new
      mail.perform_deliveries = false
      @abort = true
    else
      if !@tire_store.nil? 
        MailHelper.email_sent(self, @tire_store.id, @user.email)
        
        mail(:to => customer_issue_email_address(),
              :bcc => customer_issue_bcc_email_address(), 
              :cc => customer_issue_cc_email_address(),
              :from => 'mail@treadhunter.com',
              :subject => "Tire Store without listings")
      else
        self.message = Mail::Message.new
        mail.perform_deliveries = false
        @abort = true
      end
    end
  end
end
