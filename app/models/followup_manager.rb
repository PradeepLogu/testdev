class FollowupManager
  include ApplicationHelper
  include TireStoresHelper

  def send_no_listings_emails
    # we're only going to worry about stores created in the last month
    #
    cur_time = Time.now
    
    @email3_sent = 0
    @email10_sent = 0
    @email21_sent = 0
    
    TireStore.where(created_at: (cur_time - 1.month)..(cur_time - 3.days), private_seller: false).each do |tire_store|
      @account = tire_store.account
      @user = @account.admin_user
      
      how_long_ago = cur_time - tire_store.created_at
      
      if tire_store.tire_listings.count == 0
        if how_long_ago >= 3.days && how_long_ago < 10.days
          # send 3 day email
          FollowupMailer.delay.three_days_no_listings(@user, tire_store)#.deliver
          @email3_sent += 1
          
        elsif how_long_ago >= 10.days && how_long_ago <= 21.days
          # send 10 day email
          FollowupMailer.delay.ten_days_no_listings(@user, tire_store)#.deliver
          @email10_sent += 1
          
        else # we know it's between 21 days and a month
          # send email to internal staff
          FollowupMailer.delay.three_weeks_no_listings(@user, tire_store)#.deliver
          @email21_sent += 1
        end
      end
    end
    
    ActionMailer::Base.mail(:from => "mail@treadhunter.com", 
              :to => system_process_completion_email_address(), 
              :subject => "Processed No Listing Emails", 
              :body => "3 day: #{@email3_sent} 10 day: #{@email10_sent} 21 day: #{@email21_sent}").deliver      
  end

  def send_no_survey_emails
    # we're only going to worry about accounts created in the last month
    #
    cur_time = Time.now
    
    @email1_sent = 0
    @email3_sent = 0
    @email7_sent = 0
    @email14_sent = 0

    @session = GoogleDrive.login(google_docs_username(), google_docs_password())
    @results_spreadsheet = @session.spreadsheet_by_key(google_docs_survey_doc_id())
    @worksheet = @results_spreadsheet.worksheets.first
    @account_id_col = -1
    (1..@worksheet.max_cols).each do |i|
      if @worksheet[1, i].downcase.include?("account id")
        @account_id_col = i
        break
      end
    end

    @completed_survey_account_ids = []
    if @account_id_col > 0
      (2..@worksheet.max_rows).each do |i|
        if !@worksheet[i, @account_id_col].blank?
          puts "Adding col #{@account_id_col} from row #{i}"
          @completed_survey_account_ids << @worksheet[i, @account_id_col].to_i
        end
      end
    end
    
    Account.where(created_at: (cur_time - 1.month)..(cur_time - 3.days)).each do |account|
      @account = account
      @user = @account.admin_user
      @tire_store = @account.tire_stores.first
      
      how_long_ago = cur_time - account.created_at
      
      if @account.has_taken_survey != "true" && !@completed_survey_account_ids.include?(@account.id)
        if (how_long_ago >= 1.days && how_long_ago < 3.days)
          # send 1 day email
          FollowupMailer.delay.one_day_no_survey(@account)
          @email1_sent += 1
        elsif (how_long_ago >= 3.days && how_long_ago < 7.days)
          # send 3 day email
          FollowupMailer.delay.three_days_no_survey(@account)
          @email3_sent += 1
        elsif (how_long_ago >= 7.days && how_long_ago <= 14.days)
          # send 7 day email
          FollowupMailer.delay.seven_days_no_survey(@account)
          @email7_sent += 1
        else # we know it's between 14 days and a month
          FollowupMailer.delay.fourteen_days_no_survey(@account)
          @email14_sent += 1
        end
      end
    end
    
    ActionMailer::Base.delay.mail(:from => "mail@treadhunter.com", 
            :to => system_process_completion_email_address(), 
            :subject => "Processed No Survey Emails", 
            :body => "1 day: #{@email1_sent}\n3 day: #{@email3_sent}\n7 day: #{@email7_sent}\n14 day: #{@email14_sent}\n")
  end
  
	def process()
    send_no_listings_emails()
    send_no_survey_emails()
	end
end