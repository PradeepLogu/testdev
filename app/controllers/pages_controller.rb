include ApplicationHelper
include TireStoresHelper
include SessionsHelper

include ActionView::Helpers::NumberHelper

require 'net/http'

class PagesController < ApplicationController
  include ApplicationHelper
  newrelic_ignore :only => [:th_data]
  force_ssl :only => [:complete_order] if Rails.env.production?
  
  before_filter :authenticate
  before_filter :is_super_user, only: [:create_tirestore_spreadsheet, :find_tirestores]

  skip_before_filter :get_notifications, :only => :cc_info
  skip_before_filter :clear_return_path, :only => [:cc_info, :tireseller_home]

  def ReadData(url)
    RestClient.get url, :user_agent => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) "
    #open(url, :proxy => "http://54.243.138.45:80", "User-Agent" => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) ").read
  end

  def home
  end

  def about
  end

  def contact
  end

  def pricing
  end

  def privacy
  end

  def faq
  end

  def account_thank_you
    if params[:survey_completed].nil?
      account_id = params[:account_id]
      if account_id
        @account = Account.find(account_id)
        if @account
          @account.has_taken_survey = "true"
          @account.save 
        end
      end
    end
  end

  def survey_declined
    if params[:account_id]
      @account = Account.find(params[:account_id])
      if @account
        FollowupMailer.delay.survey_declined(@account)
      end
    end
  end

  def account_survey
    # first, let's see if this was a link generated from an email.  These do not require login, in case
    # a CSR takes the survey instead
    if !params[:secret].nil? && !params[:account_id].nil?
      @account = Account.find(params[:account_id])
      if !(@account && @account.correct_base64_account_id?(params[:secret]))
        redirect_to '/', notice: "Invalid URL."
        return
      end
    else
      if !signed_in?
        set_return_path(request.fullpath)      
        redirect_to signin_path, notice: "Please sign in."
        return
      end

      if current_user && current_user.account.nil?
        redirect_to '/', notice: "You must have an account to take this survey."
      elsif current_user.nil?
        set_return_path(request.fullpath)      
        redirect_to signin_path, notice: "Please sign in."
        return
      end

      @account = current_user.account
    end



    # let's see if this account has already taken the survey
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
    @account_found = false
    if @account_id_col > 0
      (2..@worksheet.max_rows).each do |i|
        if @worksheet[i, @account_id_col].to_i == @account.id
          @account_found = true
          break
        end
      end
    end

    if @account_found 
      redirect_to :action => "account_thank_you", :survey_completed => true, :controller => :pages
    end


    @survey_html = ""
    survey_url = "https://docs.google.com/forms/d/#{google_docs_survey_form_id()}/viewform"
    survey_response = ''
    (1..5).each do |i|
        begin
            survey_response = ReadData(survey_url)
            break
        rescue Exception => e 
            puts "Error processing survey data: #{e.to_s} - try again"
        end
    end
    if survey_response != '' # there was no error
      survey_data = Nokogiri::HTML(survey_response.to_s)
      survey_data.xpath("//form").each do |survey_form|
        survey_form.search("//form").first.set_attribute("target", "hidden_iframe")
        survey_form.search("//form").first.set_attribute("onsubmit", "submitted=true;")

        # now take all the account information and hide it...
        if true
          survey_form.xpath("//div[contains(., 'Account ID') and contains(@class, 'ss-form-question')]").first.set_attribute("style", "display: none;")
          survey_form.xpath("//div[contains(., 'Account Name') and contains(@class, 'ss-form-question')]").first.set_attribute("style", "display: none;")
          survey_form.xpath("//div[contains(., 'Contact Name') and contains(@class, 'ss-form-question')]").first.set_attribute("style", "display: none;")
          survey_form.xpath("//div[contains(., 'Contact Phone') and contains(@class, 'ss-form-question')]").first.set_attribute("style", "display: none;")
          survey_form.xpath("//div[contains(., 'Account Address') and contains(@class, 'ss-form-question')]").first.set_attribute("style", "display: none;")
        end

        survey_form.xpath("//div[contains(., 'Account ID') and contains(@class, 'ss-form-question')]//input").first.set_attribute("value", @account.id)
        survey_form.xpath("//div[contains(., 'Account Name') and contains(@class, 'ss-form-question')]//input").first.set_attribute("value", @account.name)
        survey_form.xpath("//div[contains(., 'Contact Name') and contains(@class, 'ss-form-question')]//input").first.set_attribute("value", (@current_user.nil? ? "" : @current_user.name))
        survey_form.xpath("//div[contains(., 'Contact Phone') and contains(@class, 'ss-form-question')]//input").first.set_attribute("value", (@current_user.nil? ? "" : @current_user.phone))
        survey_form.xpath("//div[contains(., 'Account Address') and contains(@class, 'ss-form-question')]//input").first.set_attribute("value", @account.full_address)

        @survey_html = survey_form
        @survey_html.search('//div[contains(@class, "ss-password-warning")]').remove
      end
    else
      @survey_html = "Unable to read survey data - please try again later."
    end
  end

  def xyzzy_abcdef
    sql = "select value from simple_captcha_data order by id desc limit 1"
    
    render :json => { :captcha => ActiveRecord::Base.connection.execute(sql).first["value"] }
  end

  def find_tirestores
    @scraper = TireStoreScraper.new
  end

  def create_tirestore_spreadsheet
    # create a delayed job
    ts = TireStoreScraper.new(params[:tire_store_scraper])
    ts.delay.scrape(true, true)
  end

  def mobile_chart_data
    @ar_mobile_usage = Array.new
    sql = "select i1.my_date, i1.map_view_scrape, i1.map_view_th, i1.store_view_th, i2.user_count
            from (select date(created_at) as my_date,
              sum(case when action_name = 'appear_on_map' 
                  and impressionable_type = 'ScrapeTireStore' then 1 else 0 end) map_view_scrape,
              sum(case when action_name = 'appear_on_map' 
                  and impressionable_type = 'TireStore' then 1 else 0 end) map_view_th,
              sum(case when action_name = 'view' 
                  and impressionable_type = 'TireStore' then 1 else 0 end) store_view_th
              from impressions 
              where controller_name = 'mobile'
              and ip_address <> '65.5.182.223'
              and created_at > (now() - INTERVAL '30 days')
              group by date(created_at)) i1
          inner join (select date(created_at) as my_date,
              count(distinct(ip_address)) as user_count
              from impressions
              where controller_name = 'mobile'
              and ip_address <> '65.5.182.223'
              and created_at > (now() - INTERVAL '30 days')
              group by date(created_at)) i2
          on (i1.my_date = i2.my_date)
          order by my_date asc"
    ActiveRecord::Base.connection.execute(sql).each do |a|
      @ar_mobile_usage << a.to_a.map{|k,v| (v.to_i.to_s == v ? v.to_i : v)}
    end
    @ar_mobile_usage.unshift(['Date', 'Scrape Mapped', 'TH Mapped', 'TH Viewed', 'Users'])

    render json: @ar_mobile_usage
  end

  def mobile_store_data
    @ar_tire_stores = Array.new
    sql = "select impressions.impressionable_id, tire_stores.contact_email as e, 
                tire_stores.name || (case when tire_stores.private_seller then ' (<b>Private</b>)' else '' end) as x, 
                date(tire_stores.created_at) as d,
                tire_stores.address1 || ', ' || tire_stores.city || ' ' || tire_stores.state as addr,
            sum (case when impressions.controller_name = 'tire_listings'
                 and impressions.created_at >= (now() - INTERVAL '7 days') then 1 else 0 end) listings_seven,
            sum (case when impressions.controller_name = 'tire_listings'
                 and impressions.created_at >= (now() - INTERVAL '30 days') then 1 else 0 end) listings_thirty,
            sum (case when impressions.controller_name = 'tire_stores'
                 and impressions.created_at >= (now() - INTERVAL '7 days') then 1 else 0 end) stores_seven,
            sum (case when impressions.controller_name = 'tire_stores'
                 and impressions.created_at >= (now() - INTERVAL '30 days') then 1 else 0 end) stores_thirty
            from impressions
            inner join tire_stores on tire_stores.id = impressions.impressionable_id
            where impressions.created_at >= (now() - INTERVAL '30 days')
            and impressions.controller_name in ('tire_listings', 'tire_stores')
            and impressions.impressionable_type = 'TireStore'
            group by impressions.impressionable_id, d, e,
                  x, tire_stores.address1 || ', ' || tire_stores.city || ' ' || tire_stores.state"
    ActiveRecord::Base.connection.execute(sql).each do |a|
      @ar_tire_stores << a.to_a.map{|k,v| (v.to_i.to_s == v ? v.to_i : v)}
    end
    @ar_tire_stores.unshift(['ID', 'Email', 'Store', 'Created', 'Address', 'List. 7 days', 'List. 30 days', 'Store 7 days', 'Store 30 days'])
    render json: @ar_tire_stores
  end

  def traffic_data
    @ar_alltraffic = Array.new
    sql = "select date(created_at), 
            sum(case when impressionable_type = 'TireStore' then 1 else 0 end) TireStore,
            sum(case when impressionable_type = 'TireListing' then 1 else 0 end) TireListing
            from impressions
            where created_at >= (now() - INTERVAL '30 days')
            and impressionable_type in ('TireStore', 'TireListing')
            group by date(created_at)
            order by date(created_at)"
    ActiveRecord::Base.connection.execute(sql).each do |a|
      @ar_alltraffic << a.to_a.map{|k,v| (v.to_i.to_s == v ? v.to_i : v)}
    end
    @ar_alltraffic.unshift(['Date', 'Store Views', 'Listing Views'])
    render json: @ar_alltraffic
  end

  def affiliate_data
    @ar_affiliates = Array.new
    @ar_affiliates << ['Day']

    affiliates = Affiliate.find(:all)

    affiliates.each do |a|
      @ar_affiliates[0] << a.name
    end

    6.step(0, -1) do |i|
      tmp = Array.new
      dt = Date.today

      tmp << (dt - i.days).to_s

      affiliates.each do |a|
        tmp << a.hits_by_date(dt - i.days)
      end

      @ar_affiliates << tmp
    end

    render json: @ar_affiliates
  end

  def mobile_impressions_data
    @ar_mobile_impressions = Array.new
    sql = "select 
            (case when scrape_tire_stores.scraper_id = 1 then 'Sears'
                  when scrape_tire_stores.scraper_id = 2 then 'Walmart'
                  when scrape_tire_stores.scraper_id = 3 then 'Goodyear'
                  when scrape_tire_stores.scraper_id = 4 then 'Bridgestone'
                  when scrape_tire_stores.scraper_id = 5 then 'Continental'
                  when scrape_tire_stores.scraper_id = 6 then 'Yokohama'
                  else 'Other' end) store_name,
            sum(case when impressions.created_at >= (now() - INTERVAL '7 days') then 1 else 0 end) impressions_week,
            sum(case when impressions.created_at >= (now() - INTERVAL '30 days') then 1 else 0 end) impressions_month,
            count(*) tot
            from impressions
            inner join scrape_tire_stores on scrape_tire_stores.id = impressions.impressionable_id
            where impressions.action_name = 'appear_on_map'
            and impressions.impressionable_type = 'ScrapeTireStore'
            group by store_name
            union
            (
            select 'Kauffman Tires' store_name,  
                        sum(case when impressions.created_at >= (now() - INTERVAL '7 days') then 1 else 0 end) impressions_week,
                        sum(case when impressions.created_at >= (now() - INTERVAL '30 days') then 1 else 0 end) impressions_month,
                        count(*) tot
                        from impressions
                        inner join scrape_tire_stores on scrape_tire_stores.id = impressions.impressionable_id
                        where impressions.action_name = 'appear_on_map'
                        and impressions.impressionable_type = 'ScrapeTireStore'
                        and scrape_tire_stores.name ilike '%kauffman%'
            ) 
            order by store_name"
    ActiveRecord::Base.connection.execute(sql).each do |a|
      @ar_mobile_impressions << a.to_a.map{|k,v| (v.to_i.to_s == v ? v.to_i : v)}
    end
    @ar_mobile_impressions.unshift(['Chain', 'Last 7 Days', 'Last 30 Days', 'All Time'])
    render json: @ar_mobile_impressions
  end

  def sources_data
    @sources = KPI::PageViewsBySource.new.to_a
    @sources.unshift(['Source', 'Page Views'])
    render json: @sources
  end

  def visits_data
    @visits_by_day = KPI::VisitsByDay.new.to_a
    @visits_by_day.unshift(['Day', 'Visits'])
    render json: @visits_by_day
  end

  def month_states_data
    @month_data_by_state = KPI::VisitsByState.new.last_month
    @month_data_by_state.unshift(['State/Region', 'Visits', '% New Visits', 'New Visits', 'Bounce Rate', 'Pages Per Visit'])
    render json: @month_data_by_state
  end

  def week_states_data
    @week_data_by_state = KPI::VisitsByState.new.last_7_days
    @week_data_by_state.unshift(['State/Region', 'Visits', '% New Visits', 'New Visits', 'Bounce Rate', 'Pages Per Visit'])
    render json: @week_data_by_state
  end

  def day_states_data
    @day_data_by_state = KPI::VisitsByState.new.last_24_hours
    @day_data_by_state.unshift(['State/Region', 'Visits', '% New Visits', 'New Visits', 'Bounce Rate', 'Pages Per Visit'])
    render json: @day_data_by_state
  end

  def th_data
    @bAjaxLoad = true

    ############# Store Metrics - Listing and Store Views ###########
    if @bAjaxLoad == false
      @ar_tire_stores = Array.new
      sql = "select impressions.impressionable_id, tire_stores.contact_email as e, 
                  tire_stores.name || (case when tire_stores.private_seller then ' (<b>Private</b>)' else '' end) as x, 
                  date(tire_stores.created_at) as d,
                  tire_stores.address1 || ', ' || tire_stores.city || ' ' || tire_stores.state as addr,
              sum (case when impressions.controller_name = 'tire_listings'
                   and impressions.created_at >= (now() - INTERVAL '7 days') then 1 else 0 end) listings_seven,
              sum (case when impressions.controller_name = 'tire_listings'
                   and impressions.created_at >= (now() - INTERVAL '30 days') then 1 else 0 end) listings_thirty,
              sum (case when impressions.controller_name = 'tire_stores'
                   and impressions.created_at >= (now() - INTERVAL '7 days') then 1 else 0 end) stores_seven,
              sum (case when impressions.controller_name = 'tire_stores'
                   and impressions.created_at >= (now() - INTERVAL '30 days') then 1 else 0 end) stores_thirty
              from impressions
              inner join tire_stores on tire_stores.id = impressions.impressionable_id
              where impressions.created_at >= (now() - INTERVAL '30 days')
              and impressions.controller_name in ('tire_listings', 'tire_stores')
              and impressions.impressionable_type = 'TireStore'
              group by impressions.impressionable_id, d, e,
                    x, tire_stores.address1 || ', ' || tire_stores.city || ' ' || tire_stores.state"
      ActiveRecord::Base.connection.execute(sql).each do |a|
        @ar_tire_stores << a.to_a.map{|k,v| (v.to_i.to_s == v ? v.to_i : v)}
      end
      @ar_tire_stores.unshift(['ID', 'Email', 'Store', 'Created', 'Address', 'List. 7 days', 'List. 30 days', 'Store 7 days', 'Store 30 days'])
    end

    ############# Traffic Metrics - Listing and Store Views ###########
    if @bAjaxLoad == false
      @ar_alltraffic = Array.new
      sql = "select date(created_at), 
              sum(case when impressionable_type = 'TireStore' then 1 else 0 end) TireStore,
              sum(case when impressionable_type = 'TireListing' then 1 else 0 end) TireListing
              from impressions
              where created_at >= (now() - INTERVAL '30 days')
              and impressionable_type in ('TireStore', 'TireListing')
              group by date(created_at)
              order by date(created_at)"
      ActiveRecord::Base.connection.execute(sql).each do |a|
        @ar_alltraffic << a.to_a.map{|k,v| (v.to_i.to_s == v ? v.to_i : v)}
      end
      @ar_alltraffic.unshift(['Date', 'Store Views', 'Listing Views'])
    end


    ############# Affiliate Metrics ###########
    if @bAjaxLoad == false
      @ar_affiliates = Array.new
      @ar_affiliates << ['Day']

      affiliates = Affiliate.find(:all)

      affiliates.each do |a|
        @ar_affiliates[0] << a.name
      end

      6.step(0, -1) do |i|
        tmp = Array.new
        dt = Date.today

        tmp << (dt - i.days).to_s

        affiliates.each do |a|
          tmp << a.hits_by_date(dt - i.days)
        end

        @ar_affiliates << tmp
      end
    end
    
    ############## Mobile Usage ############
    if @bAjaxLoad == false
      @ar_mobile_usage = Array.new
      sql = "select i1.my_date, i1.map_view_scrape, i1.map_view_th, i1.store_view_th, i2.user_count
              from (select date(created_at) as my_date,
            		sum(case when action_name = 'appear_on_map' 
            			  and impressionable_type = 'ScrapeTireStore' then 1 else 0 end) map_view_scrape,
            		sum(case when action_name = 'appear_on_map' 
            			  and impressionable_type = 'TireStore' then 1 else 0 end) map_view_th,
            		sum(case when action_name = 'view' 
            			  and impressionable_type = 'TireStore' then 1 else 0 end) store_view_th
            		from impressions 
            		where controller_name = 'mobile'
            		and ip_address <> '65.5.182.223'
            		and created_at > (now() - INTERVAL '30 days')
            		group by date(created_at)) i1
            inner join (select date(created_at) as my_date,
            		count(distinct(ip_address)) as user_count
            		from impressions
            		where controller_name = 'mobile'
            		and ip_address <> '65.5.182.223'
            		and created_at > (now() - INTERVAL '30 days')
            		group by date(created_at)) i2
            on (i1.my_date = i2.my_date)
            order by my_date asc"
      ActiveRecord::Base.connection.execute(sql).each do |a|
        @ar_mobile_usage << a.to_a.map{|k,v| (v.to_i.to_s == v ? v.to_i : v)}
      end
      @ar_mobile_usage.unshift(['Date', 'Scrape Mapped', 'TH Mapped', 'TH Viewed', 'Users'])
    end
    
    ############## Mobile Impressions *******
      if @bAjaxLoad == false
      @ar_mobile_impressions = Array.new
      sql = "select 
              (case when scrape_tire_stores.scraper_id = 1 then 'Sears'
                    when scrape_tire_stores.scraper_id = 2 then 'Walmart'
                    when scrape_tire_stores.scraper_id = 3 then 'Goodyear'
                    when scrape_tire_stores.scraper_id = 4 then 'Bridgestone'
                    when scrape_tire_stores.scraper_id = 5 then 'Continental'
                    when scrape_tire_stores.scraper_id = 6 then 'Yokohama'
                    else 'Other' end) store_name,
              sum(case when impressions.created_at >= (now() - INTERVAL '7 days') then 1 else 0 end) impressions_week,
              sum(case when impressions.created_at >= (now() - INTERVAL '30 days') then 1 else 0 end) impressions_month,
              count(*) tot
              from impressions
              inner join scrape_tire_stores on scrape_tire_stores.id = impressions.impressionable_id
              where impressions.action_name = 'appear_on_map'
              and impressions.impressionable_type = 'ScrapeTireStore'
              group by store_name
              union
              (
              select 'Kauffman Tires' store_name,  
                          sum(case when impressions.created_at >= (now() - INTERVAL '7 days') then 1 else 0 end) impressions_week,
                          sum(case when impressions.created_at >= (now() - INTERVAL '30 days') then 1 else 0 end) impressions_month,
                          count(*) tot
                          from impressions
                          inner join scrape_tire_stores on scrape_tire_stores.id = impressions.impressionable_id
                          where impressions.action_name = 'appear_on_map'
                          and impressions.impressionable_type = 'ScrapeTireStore'
                          and scrape_tire_stores.name ilike '%kauffman%'
              ) 
              order by store_name"
      ActiveRecord::Base.connection.execute(sql).each do |a|
        @ar_mobile_impressions << a.to_a.map{|k,v| (v.to_i.to_s == v ? v.to_i : v)}
      end
      @ar_mobile_impressions.unshift(['Chain', 'Last 7 Days', 'Last 30 Days', 'All Time'])
    end

    if @bAjaxLoad == false
      @sources = KPI::PageViewsBySource.new.to_a
      @sources.unshift(['Source', 'Page Views'])
    end
    
    if @bAjaxLoad == false
      @visits_by_day = KPI::VisitsByDay.new.to_a
      @visits_by_day.unshift(['Day', 'Visits'])
    end
    
    if @bAjaxLoad == false
      @month_data_by_state = KPI::VisitsByState.new.last_month
      @month_data_by_state.unshift(['State/Region', 'Visits', '% New Visits', 'New Visits', 'Bounce Rate', 'Pages Per Visit'])
    end

    if @bAjaxLoad == false
      @week_data_by_state = KPI::VisitsByState.new.last_7_days
      @week_data_by_state.unshift(['State/Region', 'Visits', '% New Visits', 'New Visits', 'Bounce Rate', 'Pages Per Visit'])
    end

    if @bAjaxLoad == false
      @day_data_by_state = KPI::VisitsByState.new.last_24_hours
      @day_data_by_state.unshift(['State/Region', 'Visits', '% New Visits', 'New Visits', 'Bounce Rate', 'Pages Per Visit'])
    end
  end
  
  def th_city_data
    k = KPI::VisitsByCity.new
    k.setState(params[:state_name])
    time_period = params[:time_period]
    if time_period.downcase == "day"
      @data = k.last_24_hours
    elsif time_period.downcase == "week"
      @data = k.last_7_days
    else
      @data = k.last_month
    end
    @data.unshift(['City', 'Visits', '% New Visits', 'New Visits', 'Bounce Rate', 'Pages Per Visit'])
    render json: @data.to_json
  end
  
  def set_store_type
    if !params[:new].nil?
      session[:store_type] = "new"
      respond_to do |format|
        if !params[:ref].nil?
          format.html { redirect_to '/nt_landing?direct=true&ref=' + params[:ref] }
        else
          format.html { redirect_to '/nt_landing?direct=true' }
        end
      end
    else
      session[:store_type] = "used"
      respond_to do |format|
        if !params[:ref].nil?
          format.html { redirect_to '/ut_landing?direct=true&ref=' + params[:ref] }
        else
          format.html { redirect_to '/ut_landing?direct=true' }
        end
      end      
    end
  end
  
  def set_seller_type
    if !params[:private].nil?
      session[:store_type] = "private"
      respond_to do |format|
        if !params[:ref].nil?
          format.html { redirect_to '/th_landing?store_type=private&ref=' + params[:ref] }
        else
          format.html { redirect_to '/th_landing?store_type=private' }
        end
      end
    elsif !params[:used].nil?
      session[:store_type] = "used"
      respond_to do |format|
        if !params[:ref].nil?
          format.html { redirect_to '/th_landing?store_type=used&ref=' + params[:ref] }
        else
          format.html { redirect_to '/th_landing?store_type=used' }
        end
      end      
    else
      session[:store_type] = "new"
      respond_to do |format|
        if !params[:ref].nil?
          format.html { redirect_to '/th_landing?store_type=new&ref=' + params[:ref] }
        else
          format.html { redirect_to '/th_landing?store_type=new' }
        end
      end      
    end
  end

  def ut_landing
    if !params[:ref].blank?
      @affiliate = Affiliate.find_by_affiliate_tag(params[:ref].downcase)
    elsif !current_user.nil? && !current_user.affiliate_referrer.nil?
      @affiliate = Affiliate.find_by_affiliate_tag(current_user.affiliate_referrer.downcase)
    else
      @affiliate = nil
    end

    if !@affiliate.nil?
      impressionist(@affiliate, :unique => [:ip_address])
    end
  end

  def nt_landing
    if !params[:ref].blank?
      @affiliate = Affiliate.find_by_affiliate_tag(params[:ref].downcase)
    elsif !current_user.nil? && current_user.affiliate_referrer
      @affiliate = Affiliate.find_by_affiliate_tag(current_user.affiliate_referrer.downcase)
    else
      @affiliate = nil
    end

    if !@affiliate.nil?
      impressionist(@affiliate, :unique => [:ip_address])
    end
  end

  def th_landing
    @registration = Registration.new
    
    if !params[:ref].blank?
      @affiliate = Affiliate.find_by_affiliate_tag(params[:ref].downcase)
    elsif !current_user.nil? && current_user.affiliate_referrer
      @affiliate = Affiliate.find_by_affiliate_tag(current_user.affiliate_referrer.downcase)
    else
      @affiliate = nil
    end

    if !@affiliate.nil?
      impressionist(@affiliate, :unique => [:ip_address])
    end
  end

  def home_tb
    prep_home_page
    render :home_tb, :layout => false
  end

  def home_visfire
    prep_home_page
    render :home_visfire, :layout => false
  end

  def prep_home_page
    @default_tab = 1
    @tire_search = TireSearch.new
    load_default_search_data

    if params[:mode960] && params[:mode960] == "false"
      @new_res = false
    else
      @new_res = true
    end

    @radii = []
    @radii << ['Search radius:', '']
    TireSearch::RADIUS_CHOICES.each do |a|
      if a.class.to_s == "Array"
        @radii << a
      else
        tmp = []
        tmp << a + " miles" << a
        @radii << tmp
      end
    end

    @featured = params[:featured]
    if @featured.nil?
      @featured = "bwbrands"
    else
      @featured = @featured.downcase
    end

    #@show_get_treadhunter_news_footer = false
    #if !params[:news].nil? && params[:news].length > 0
    #  @show_get_treadhunter_news_footer = true
    #end
    @show_get_treadhunter_news_footer = true

    @show_michelin = false
    @show_th_mobile_ad = true
  end    

  def tireseller_registration
    @user = User.new
  end
  
  def th_unified
    # this method will create a new user, account, and store.
    @registration = Registration.new(params[:registration])
    
    aff_tag = request.env['affiliate.tag']
    if aff_tag.blank?
      @affiliate_tag = nil
    else
      @affiliate_tag = aff_tag.truncate(252)
    end
    
    puts "**** th_unified - #{@affiliate_tag}"

    begin
      if !@affiliate_tag.nil?
        @affiliate = Affiliate.find_by_affiliate_tag(@affiliate_tag)
        if !@affiliate.nil?      
          @registration.user.affiliate_id       = @registration.tire_store.affiliate_id       = @registration.account.affiliate_id       = @affiliate.id
          @registration.user.affiliate_time     = @registration.tire_store.affiliate_time     = @registration.account.affiliate_time     = (request.env['affiliate.time'].nil? ? Time.now : Time.at(env['affiliate.time']))
          @registration.user.affiliate_referrer = @registration.tire_store.affiliate_referrer = @registration.account.affiliate_referrer = (request.env['affiliate.from'].blank? ? "referral_code" : request.env['affiliate.from'].truncate(252))
        else
          puts "**** th_unified - Could not find affiliate"
        end
      end
    rescue Exception => e
      puts "*** ERROR TH_UNIFIED: #{e.to_s}"
      # not going to worry about it
    end
    
    @registration.user.tireseller = true

    respond_to do |format|
      if @registration.save
        sign_in @registration.user
        
        if @registration.store_type.downcase != "private"
          # 04/22/13 Send the 'welcome' email
          OnBoardMailer.delay.on_board_email(current_user)

          if create_contracts
            # let's create a contract for this user.  It will tie to the "free" plan.
            @registration.account.create_free_trial_contract()

            # now create a regular contract that will begin when the free trial expires
            @registration.account.create_gold_contract()
            #@registration.account.create_platinum_contract()
            
            if collect_cc_upfront
              if secure_cc
                format.html { redirect_to :action => "cc_info", :tire_store_id => @registration.tire_store.id, :controller => :pages, :protocol => 'https://' }
              else
                format.html { redirect_to :action => "cc_info", :tire_store_id => @registration.tire_store.id, :controller => :pages }
              end
            end            
          end             
        else
          OnBoardMailer.delay.on_board_email_private_seller(current_user)
        end     
        
        @user = @registration.user
        @tire_store = @registration.tire_store
        @account = @registration.account

        #format.html { redirect_to 'registration_successful' }
        puts "*** REGISTRATION SUCCESS ***"
        format.html { render action: :registration_success }        
        # format.json { render json: @user, status: :created, location: @user }
      else
        format.html { render action: "th_landing" }
        # format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  def tireseller_create
    @user = User.new(params[:user])
    @user.tireseller = true

    aff_tag = request.env['affiliate.tag']
    if aff_tag.blank?
      @affiliate_tag = nil
    else
      @affiliate_tag = aff_tag.truncate(252)
    end

    if @affiliate_tag.nil?
      @affiliate_tag = params[:referral_code].downcase
      if @affiliate_tag == "sands60" || @affiliate_tag == "s&s123"
        @affiliate_tag = "sands"
      elsif @affiliate_tag == "promo" || @affiliate_tag == "40off"
        @affiliate_tag = "promo"
      end
    end

    aff_id = ""

    if !@affiliate_tag.nil?
      aff_id = @affiliate_tag.to_s
      if aff_id.length > 0
        @affiliate = Affiliate.find_by_affiliate_tag(aff_id)
        if !@affiliate.nil?
          begin
            @user.affiliate_id = @affiliate.id
            if request.env['affiliate.time'].nil?
              @user.affiliate_time = Time.now
            else
              @user.affiliate_time = Time.at(env['affiliate.time'])
            end
            if request.env['affiliate.from'].blank?
              @user.affiliate_referrer = "referral_code"
            else
              @user.affiliate_referrer = request.env['affiliate.from'].truncate(252)
            end
          rescue
            # not going to worry about it...
          end
        end
      end
    end

    respond_to do |format|
      @account = Account.new(:name => params[:account_name], 
                              :phone => @user.phone, :address1 => 'not set',
                              :city => 'Atlanta', :state => 'GA', :zipcode => @user.zipcode,
                              :billing_email => @user.email)
      if @account.save
        @user.account_id = @account.id 
        if @user.save
          sign_in @user

          if aff_id.blank?
            format.html { redirect_to pages_pricing_url }
          else
            format.html { redirect_to pages_pricing_url + "?ref=" + aff_id }
          end
          format.json { render json: @user, status: :created, location: @user }
        else
          ####format.json { render json: @user.errors, status: :unprocessable_entity }
          @create_errors = "<p>"
          @user.errors.each do |fld, err|
            @create_errors += "<%= fld %>: <%= err %><br />"
          end
          @create_errors += "</p>"
          format.js
        end
      else
        # format.html { render action: "tireseller_registration" }
        ###format.json { render json: @account.errors, status: :unprocessable_entity }
        if true
          format.json { render json: @account.errors, status: 401}
        else          
          format.json { render json: @account.errors, status: 401}
        end
      end
    end
  end

  def transfer_from_prod
    # we need to hit the production site and get this tire store
    # first, let's transfer the account
    store_URI = URI("http://www.treadhunter.com/tire_store/transfer/#{params[:tire_store_id]}.json")

    req = Net::HTTP::Get.new(store_URI.request_uri)
    req.basic_auth 'guest', 'SellinTires'
    resp = Net::HTTP.start(store_URI.host, store_URI.port) {|http|
      http.request(req)
    }

    @tire_store = TireStore.new()
    @tire_store.attributes = JSON.parse(resp.body)
    @tire_store.save

    # now we need to get the account record, create a new account with the data,
    # and update our tire store record with the proper account
    account_URI = URI("http://www.treadhunter.com/account/transfer/#{@tire_store.account_id}.json")
    req = Net::HTTP::Get.new(account_URI.request_uri)
    req.basic_auth 'guest', 'SellinTires'
    resp = Net::HTTP.start(store_URI.host, store_URI.port) {|http|
      http.request(req)
    }

    @account = Account.new()
    @account.attributes = JSON.parse(resp.body)
    @account.save

    @tire_store.update_attribute(:account_id, @account.id)

    # let's create new listings for this store.

    # this is a bit goofy.  We need separate transactions for the pictures and the listings.
    # So.....we have to do the following:
    # (1) Get a list of all IDs
    # (2) For each ID, get all information except the pictures
    # (3) Get the pictures and re-save them

    listings_URI = URI("http://www.treadhunter.com/tire_listings/transfer/#{params[:tire_store_id]}.json")
    req = Net::HTTP::Get.new(listings_URI.request_uri)
    req.basic_auth 'guest', 'SellinTires'
    resp = Net::HTTP.start(listings_URI.host, listings_URI.port) {|http|
      http.request(req)
    }
    @listing_IDs = JSON.parse(resp.body)
    @listing_IDs.each do |i|
      puts "ID: #{i['id']} MANU: #{i['manufacturer_name']} MODEL: #{i['model_name']} SIZE: #{i['sizestr']}"
      @tire_size = TireSize.find_or_create_by_sizestr(i['sizestr'])
      @manu = TireManufacturer.find_or_create_by_name(i['manufacturer_name'])
      @model = TireModel.find_or_create_by_tire_manufacturer_id_and_tire_size_id_and_name(@manu.id, @tire_size.id, i['model_name'])
    
      listing_URI = URI("http://www.treadhunter.com/tire_listing/transfer/#{i['id']}.json")
      req = Net::HTTP::Get.new(listing_URI.request_uri)
      req.basic_auth 'guest', 'SellinTires'
      resp = Net::HTTP.start(listing_URI.host, listing_URI.port) {|http|
        http.request(req)
      }

      # we should have a hash that we can turn into a listing now
      @listing = TireListing.new()
      @listing.attributes = JSON.parse(resp.body)
      @listing.tire_store_id = @tire_store.id
      @listing.tire_manufacturer_id = @manu.id
      @listing.tire_model_id = @model.id
      @listing.tire_size_id = @tire_size.id
      @listing.price = i['formatted_price']

      # now, we have to process the pictures.
      if i['photo1_thumbnail']
        @listing.photo1 = open(i['photo1_thumbnail'])
      end
      if i['photo2_thumbnail']
        @listing.photo2 = open(i['photo2_thumbnail'])
      end
      if i['photo3_thumbnail']
        @listing.photo3 = open(i['photo3_thumbnail'])
      end
      if i['photo4_thumbnail']
        @listing.photo4 = open(i['photo4_thumbnail'])
      end

      @listing.save
    end

    # Now let's get the branding for this store.
    branding_URI = URI("http://www.treadhunter.com/tire_store_branding/transfer/#{params[:tire_store_id]}.json")
    req = Net::HTTP::Get.new(branding_URI.request_uri)
    req.basic_auth 'guest', 'SellinTires'
    resp = Net::HTTP.start(branding_URI.host, branding_URI.port) {|http|
      http.request(req)
    }
    branding_parsed = JSON.parse(resp.body)
    branding = Branding.new(:tire_store_id => @tire_store.id)
    branding.logo = open(branding_parsed['logo_url'])
    branding.save

    # we have our store and account, and they are in pretty good shape.  Let's
    # find our users for this account.  If they already exist, we'll just update the account
    # number.  If not, we'll create a new one.

    redirect_to @tire_store, notice: "Created store from #{request.protocol}#{request.host_with_port}#{request.fullpath}"
  end

  def merge_array(stores, field_to_merge, column_to_sum, divisor)
    has_added = false
    array_of_values = nil
    num_ecomm_stores = 0
    stores.each do |t|
      if t.can_do_ecomm?
        num_ecomm_stores += 1
        if has_added == false
          # just set the array of values to be our first store's data
          has_added = true
          array_of_values = t.send(field_to_merge).map{|o| [o["group_field"], (o[column_to_sum].to_i / divisor)]}
        else
          # merge with existing array - I have no doubt there's a better Ruby way to do this...
          new_array = t.send(field_to_merge).map{|o| [o["group_field"], (o[column_to_sum].to_i / divisor)]}
          array_of_values.each do |ar|
            # search in new_array for the key...if found, add its order_total to the existing array.
            # if not found, add 0 to the existing array
            existing_element = new_array.select{|key, value| key==ar[0]}
            if existing_element == []
              # the new store does not have this month, so we need to append a zero value
              ar << 0
            else
              # the new store does have this month, so add its value to our existing array
              ar << existing_element[0][1]
            end
          end
          
          # now our array has merged with the new store, appending its values for existing months.
          # we need to see if there are any months that exist in the new store that don't exist for the first
          # store.
          new_array.each do |ar|
            existing_element = array_of_values.select{|key, value| key==ar[0]}
            if existing_element == []
              new_dataset = Array.new(num_ecomm_stores + 1, 0)
              new_dataset[0] = ar[0]
              new_dataset[num_ecomm_stores] = ar[1]
              array_of_values << new_dataset
            end
          end

          # now we need to see if there were months in the existing array that have not been properly
          # expanded...
          array_of_values.each do |ar|
            if ar.size < (num_ecomm_stores + 1)
              ar << 0
            end
          end
        end
      end
    end

    return array_of_values.sort_by{|e| e[0]}
  end

  def sales_charts
    if !signed_in?
      set_return_path(request.fullpath)      
      redirect_to signin_path, notice: "Please sign in."
    elsif current_user.is_tirebuyer? && !super_user?
      redirect_to '/', notice: "You do not have access to that page."
    else
      @account = current_user.account
      if !@account && !super_user?
        redirect_to '/accounts/new', notice: "You do not have an account set up."
      end

      backtrace_log if backtrace_logging_enabled

      @tire_stores = @account.tire_stores

      @weekly_orders_table = GoogleVisualr::DataTable.new
      @weekly_orders_table.new_column('string', 'Week' )
      @tire_stores.each do |t|
        if t.can_do_ecomm?
          @weekly_orders_table.new_column('number', t.name)
        end
      end
      @weekly_orders_table.add_rows(merge_array(@tire_stores, "get_weekly_order_history", "order_total", 100.0).map{|ar| ([ar[0][0..3] + " week " + ar[0][4..99]] | ar.drop(1))})
      option = { width: 640, height: (@weekly_orders_table.rows.count * 18), title: 'Weekly Orders - Dollars', :legend => 'bottom' }
      @weekly_order_amount = GoogleVisualr::Interactive::BarChart.new(@weekly_orders_table, option)
      backtrace_log if backtrace_logging_enabled


      @weekly_orders_count_table = GoogleVisualr::DataTable.new
      @weekly_orders_count_table.new_column('string', 'Week' )
      @tire_stores.each do |t|
        if t.can_do_ecomm?
          @weekly_orders_count_table.new_column('number', t.name)
        end
      end
      @weekly_orders_count_table.add_rows(merge_array(@tire_stores, "get_weekly_order_history", "order_count", 1).map{|ar| ([ar[0][0..3] + " week " + ar[0][4..99]] | ar.drop(1))})
      option = { width: 640, height: (@weekly_orders_count_table.rows.count * 18), title: 'Weekly Orders - Count', :legend => 'bottom' }
      @weekly_order_count = GoogleVisualr::Interactive::BarChart.new(@weekly_orders_count_table, option)
      backtrace_log if backtrace_logging_enabled


      @weekly_orders_tires_table = GoogleVisualr::DataTable.new
      @weekly_orders_tires_table.new_column('string', 'Week' )
      @tire_stores.each do |t|
        if t.can_do_ecomm?
          @weekly_orders_tires_table.new_column('number', t.name)
        end
      end
      @weekly_orders_tires_table.add_rows(merge_array(@tire_stores, "get_weekly_order_history", "order_total_tires", 1).map{|ar| ([ar[0][0..3] + " week " + ar[0][4..99]] | ar.drop(1))})
      option = { width: 640, height: (@weekly_orders_tires_table.rows.count * 18), title: 'Weekly Orders - Units', :legend => 'bottom' }
      @weekly_tires_count = GoogleVisualr::Interactive::BarChart.new(@weekly_orders_tires_table, option)
      backtrace_log if backtrace_logging_enabled


      @monthly_orders_table = GoogleVisualr::DataTable.new
      @monthly_orders_table.new_column('string', 'Month' )
      @tire_stores.each do |t|
        if t.can_do_ecomm?
          @monthly_orders_table.new_column('number', t.name)
        end
      end
      # this funky code below takes the first element of each array, e.g. "201501" and converts it to engrish e.g. Jan 2015
      @monthly_orders_table.add_rows(merge_array(@tire_stores, "get_monthly_order_history", "order_total", 100.0).map{|ar| ([Date.parse(ar[0] + "01").strftime("%b %Y")] | ar.drop(1))} )
      option = { width: 640, height: (@monthly_orders_table.rows.count * 18), title: 'Monthly Orders - Dollars', :legend => 'bottom' }
      @monthly_order_amount = GoogleVisualr::Interactive::BarChart.new(@monthly_orders_table, option)
      backtrace_log if backtrace_logging_enabled


      @monthly_orders_count_table = GoogleVisualr::DataTable.new
      @monthly_orders_count_table.new_column('string', 'Month' )
      @tire_stores.each do |t|
        if t.can_do_ecomm?
          @monthly_orders_count_table.new_column('number', t.name)
        end
      end

      @monthly_orders_count_table.add_rows(    merge_array(@tire_stores, "get_monthly_order_history", "order_count", 1).map{|ar| ([Date.parse(ar[0] + "01").strftime("%b %Y")] | ar.drop(1))}   )
      option = { width: 640, height: (@monthly_orders_count_table.rows.count * 18), title: 'Monthly Orders - Count', :legend => 'bottom' }
      @monthly_order_count = GoogleVisualr::Interactive::BarChart.new(@monthly_orders_count_table, option)
      backtrace_log if backtrace_logging_enabled


      @monthly_orders_tires_table = GoogleVisualr::DataTable.new
      @monthly_orders_tires_table.new_column('string', 'Month' )
      @tire_stores.each do |t|
        if t.can_do_ecomm?
          @monthly_orders_tires_table.new_column('number', t.name)
        end
      end
      @monthly_orders_tires_table.add_rows(merge_array(@tire_stores, "get_monthly_order_history", "order_total_tires", 1).map{|ar| ([Date.parse(ar[0] + "01").strftime("%b %Y")] | ar.drop(1))} )
      option = { width: 640, height: (@monthly_orders_tires_table.rows.count * 18), title: 'Monthly Orders - Units', :legend => 'bottom' }
      @monthly_tires_count = GoogleVisualr::Interactive::BarChart.new(@monthly_orders_tires_table, option)
      backtrace_log if backtrace_logging_enabled
    end

    render :layout => false
  end

  # this happens after CC info is entered, and sends user to create an appointment.
  def create_order
    @order = Order.find(params[:order_id])
    @tire_listing = TireListing.find(params[:tire_listing_id])

    # can we find it?  If not we need to recreate it.
    if !@order.stripe_buyer_customer_token.blank?
      begin
        @customer = Stripe::Customer.retrieve(@order.stripe_buyer_customer_token)
      rescue Exception => e
        # could not retrieve the customer record, so let's just re-create the customer
        @customer = nil 
        @order.stripe_buyer_customer_token = ""
      end
    end

    if @order.stripe_buyer_customer_token.blank?
      begin
        @customer = Stripe::Customer.create(:card => params[:stripeToken], :description => params[:email])
      rescue Exception => e
        @order.destroy
        redirect_to @order.tire_listing, notice: "There was an error with your data - message: #{e.to_s}"
        return
      end
      @order.stripe_buyer_customer_token = @customer.id
      @order.uuid = SecureRandom.uuid
    elsif @customer.nil?
      @customer = Stripe::Customer.retrieve(@order.stripe_buyer_customer_token)
    end

    stripe_buyer_customer_cc_token = @customer.default_source #@customer.active_card.id
    @order.buyer_name = @customer.sources.first.name #@customer.active_card.name
    @order.buyer_email = params[:email]
    @order.buyer_phone = params[:phone]
    @order.notify_buyer_with_text = params[:notify_buyer_via_text]
    @order.buyer_address1 = @customer.sources.first.address_line1 #@customer.active_card.address_line1
    @order.buyer_city = @customer.sources.first.address_city #@customer.active_card.address_city
    @order.buyer_state = @customer.sources.first.address_state #@customer.active_card.address_state
    @order.buyer_zip = @customer.sources.first.address_zip #@customer.active_card.address_zip

    @order.status = order_status_array[:ready_for_billing]
    @order.save

    @order.delay.bill_order

    flash[:alert] = 'Your credit card will be billed shortly.  It is important for you to schedule an appointment time now to complete the order.  You will receive a confirmation email in 10 minutes -OR- after scheduling your appointment.'
    redirect_to :action => :new, :controller => :appointments, :tire_store_id => @order.tire_listing.tire_store_id, :tire_listing_id => @order.tire_listing_id, :order_id => @order.id, :order_uuid => @order.uuid
  end

  def initialize_order
    unless current_user.nil?
      @order.user_id = current_user.id
    end
  end

  # happens after user clicks I Want These Tires but has not filled out info yet.
  # this will be an SSL page that collects CC info
  def complete_order
    @tire_listing = TireListing.find(params[:tire_listing_id])

    if !@tire_listing.can_do_ecomm?
      redirect_to @tire_listing, notice: "Those tires are not eligible for online purchase."
    end

    @ar_months = Date::MONTHNAMES.each_with_index.collect{|m, i| [m, i.to_s.rjust(2, '0')]}
    @ar_years = [*Date.today.year..Date.today.year + 8]

    @qty = params[:qty].to_i
    @order = Order.new(:tire_listing_id => @tire_listing.id, :tire_quantity => @qty)
    @order.status = order_status_array[:created]
    @order.calculate_total_order
    @order.buyer_email = @order.buyer_name = @order.buyer_address1 = @order.buyer_city = @order.buyer_state = @order.buyer_zip = "unknown" # to prevent null error
    initialize_order
    @order.save
  end

  def tireseller_home
    if !signed_in?
      set_return_path(request.fullpath)      
      redirect_to signin_path, notice: "Please sign in."
    elsif current_user.is_tirebuyer? && !super_user?
      redirect_to '/', notice: "You do not have access to that page."
    else
      @account = current_user.account
      if !@account && !super_user?
        redirect_to '/accounts/new', notice: "You do not have an account set up."
      end
    end
  end

  def tireseller_home_tabs
    if !signed_in?
      set_return_path(request.fullpath)      
      redirect_to signin_path, notice: "Please sign in."
    elsif current_user.is_tirebuyer? && !super_user?
      redirect_to '/', notice: "You do not have access to that page."
    else
      @account = current_user.account
      if !@account && !super_user?
        redirect_to '/accounts/new', notice: "You do not have an account set up."
      end
      
      if params[:start_tab]
        @start_tab = params[:start_tab]
      end      
      @start_tab = :storefront if !params[:create_storefront].blank?
    end
  end

  def get_financial_data
    if !signed_in?
      set_return_path(request.fullpath)      
      redirect_to signin_path, notice: "Please sign in."
    elsif request.post?
      # validate data, get token, etc.
      @tire_store = TireStore.find_by_id(params[:tire_store_id])
      if @tire_store.nil?
          redirect_to '/', notice: "No tire store."
      end

      @account = current_user.account
      if @account
        if @account.id != @tire_store.account_id
          redirect_to '/', notice: "You are trying to update a store that does not belong to you."
        else
          # we have a tire store and an account, should be good to move forward.
          if true
            if @tire_store.stripe_account_record.nil?
              begin
                @tire_store.update_stripe_recipient_data_bank_account(params[:businessName],
                      params[:businessType], params[:taxID], params[:accountToken])
                redirect_to '/myTreadHunter', notice: "Tire store has been updated."
              rescue Exception => e
                puts "got an error in update_stripe_recipient_data_bank_account"
                flash[:alert] = e.to_s 
                return
              end
            else
              # just need to update
              @tire_store.update_stripe_recipient_data_bank_account(params[:businessName], 
                  params[:businessType], params[:taxID], params[:accountToken])
              redirect_to '/myTreadHunter', notice: "Tire store has been updated."
            end
          else
            if @tire_store.stripe_recipient_record.nil?
              begin
                if params[:data_type].downcase == "a"
                  @tire_store.update_stripe_recipient_data_bank_account(params[:businessName],
                      params[:businessType], params[:taxID], params[:accountToken])
                else 
                  @tire_store.update_stripe_recipient_data_debit_card(params[:businessName],
                      params[:businessType], params[:taxID], params[:cardToken])
                end

              rescue Exception => e
                flash[:alert] = e.to_s
                return
              end

              if @account.default_routing_number.blank?
                @account.default_routing_number = params[:routingNumber]
                @account.save
              end

              if !@tire_store.stripe_recipient_record.nil?
                redirect_to '/myTreadHunter', notice: "Tire store has been updated."
              else
                flash[:alert] = "Update failed."
              end
            else
              # just need to update
              if params[:data_type].downcase == "a"
                @tire_store.update_stripe_recipient_data_bank_account(params[:businessName], 
                  params[:businessType], params[:taxID], params[:accountToken])
              else
                @tire_store.update_stripe_recipient_data_debit_card(params[:businessName], 
                  params[:businessType], params[:taxID], params[:cardToken])
              end
              redirect_to '/myTreadHunter', notice: "Tire store has been updated."
            end
          end
        end
      else
        if current_user.nil?
          redirect_to '/', notice: "You must be logged in."
        else
          redirect_to '/myTreadHunter', notice: "You do not have an account.  Please contact TreadHunter for assistance."
        end
      end
    else
      # must be a get.  Do we have a tire store?  If not, use the default.
      @account = current_user.account 
      if !params[:tire_store_id].blank?
        @tire_store = TireStore.find_by_id(params[:tire_store_id])
      end
      if @tire_store.nil?
        @tire_store = current_user.account.tire_stores.first
      end
      if @tire_store.nil?
        redirect_to '/myTreadHunter', notice: "You do not have a tire store established.  Please create one or contact TreadHunter for assistance."
      end
    end
  end

  def clean_test_data
    if Rails.env.development?
      @user = User.find_by_email('bobs_tires@irick.net')
      if @user 
        @account = @user.account 
        if @account
          begin
            @account.delete_from_stripe
            @account.tire_stores.each do |t|
              t.delete_from_stripe
            end
          rescue Exception => e 
            # not gonna worry about it
          end
          @account.destroy
        end
          
        @user.destroy
      end

      sign_out
      redirect_to '/th_landing'
    else
      redirect_to '/', notice: "Invalid function."
    end
  end

  def cc_info
    # first, we MUST have a logged in user.
    if current_user.nil?
      # get a session and redirect back here
      set_return_path(request.fullpath)
      redirect_to '/signin', notice: "You must be logged in to access that page."
      return
    end

    @account = current_user.account

    # next, this user MUST have an account set up.
    if @account.nil?
      redirect_to '/', notice: "You must create or select an account"
      return
    end

    # if account doesn't have a contract, let's set one up for him.
    if @account.current_contract.nil?
      @account.create_free_trial_contract
      @account.create_platinum_contract
    end

    # does the account have a Stripe customer ID yet?
    if !@account.validate_stripe_id
      @account.register_with_stripe()
      if !@account.validate_stripe_id
        redirect_to '/', notice: "We are having trouble validating the account with the credit card processor.  Try back later."
        return
      end
    end
  end

  def index
    @tire_search = TireSearch.new
    load_default_search_data
  end

  def newhome
    @tire_search = TireSearch.new
    load_default_search_data
  end

  def home_unified
    @tire_search = TireSearch.new
    load_default_search_data
  end
  
  private
    def load_default_search_data
      @manufacturers = AutoManufacturer.order("name")
      @models = AutoModel.where(:auto_manufacturer_id => session[:manufacturer_id])
      @years = AutoYear.where(:auto_model_id => session[:auto_model_id])
      @options = AutoOption.where(:auto_year_id => session[:auto_year_id])

      @diameters = TireSize.all_diameters
      @ratios = TireSize.all_ratios(session[:diameter])
      @wheeldiameters = TireSize.all_wheeldiameters(session[:ratio])

      if (!session[:diameter].blank?)
        @default_tab = 2
      else
        @default_tab = 1
      end

      if session[:location].blank?
        # let's try to set based on geoip
        begin
          loc = Geocoder.search(request.remote_ip)[0]
          if loc && !loc.city.blank?
            session[:location] = loc.city + ', ' + loc.state
          end
        rescue
          puts "**** EXCEPTION"
        end
      end

      nil
    end
end
