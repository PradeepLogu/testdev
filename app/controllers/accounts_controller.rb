class AccountsController < ApplicationController
before_filter :correct_user, only: [:edit, :update, :show, :destroy]
#before_filter :signed_in, only: [:new]
before_filter :is_super_user, only: [:index, :use]

  include AccountsHelper
  include ApplicationHelper
  # GET /accounts
  # GET /accounts.json
  def index
    if super_user?
      @show_su_functions = true
      @submenu = Hash.new
      @submenu[:menu] = "Admin"
      @submenu[:items] = []
      @submenu[:items] << {href: reservations_path, link: "View all reservations in system"}
      @submenu[:items] << {href: "/tire_stores/stats", link: "View traffic stats by store"}
    else
      @show_su_functions = false
    end

    @accounts = Account.search(params)
    @accounts = @accounts.paginate(page: params[:page]) unless @accounts.nil?

    @state = params[:State]

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @accounts }
    end
  end

  def use
    if params[:id] == '0'
      current_user.update_attribute(:account_id, 0)
    else
      @account = Account.find(params[:id])
      current_user.update_attribute(:account_id, @account.id)
    end
    sign_in current_user
    redirect_to '/myTreadHunter'
  end

  # GET /accounts/1
  # GET /accounts/1.json
  def show
    @account = Account.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @account }
    end
  end

  # GET /accounts/new
  # GET /accounts/new.json
  def new
    if current_user.nil?
      redirect_to "/signup", :alert => "You need to register first."
      return
    end

    if !current_user.account.nil?
      redirect_to current_user, :alert => "You already have an account set up."
      return
    end

    @account = Account.new

    if params[:type] && params[:type].downcase == 'private'
      @account.name = current_user.name
      @account.phone = current_user.phone
      @private_seller = true
    else
      @private_seller = false
    end

    @account.billing_email = current_user.email

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @account }
    end
  end

  # GET /accounts/1/edit
  def edit
    @account = Account.find(params[:id])
  end

  def transfer
    @account = Account.find(params[:id])
    respond_to do |format|
      format.json { render :json => @account, :except => [:id, :created_at, :updated_at, :latitude] }
    end
  end

  # POST /accounts
  # POST /accounts.json
  def create
    @account = Account.new(params[:account])

    unless current_user.nil?
      @account.affiliate_id = current_user.affiliate_id
      @account.affiliate_time = current_user.affiliate_time
      @account.affiliate_referrer = current_user.affiliate_referrer
    end

    if params[:type] && params[:type].downcase == 'private'
      @account.billing_email = current_user.email unless current_user.nil?
    end

    respond_to do |format|
      if @account.save
        @tire_store = nil

        # does user want us to create a tire store?
        if params[:createStore] == 'yes' || (params[:type] && params[:type].downcase == 'private')
          @tire_store = TireStore.new
          @tire_store.address1 = @account.address1
          @tire_store.address2 = @account.address2
          @tire_store.phone = @account.phone
          @tire_store.city = @account.city
          @tire_store.state = @account.state
          @tire_store.zipcode = @account.zipcode
          if current_user.nil?
            @tire_store.contact_email = @account.billing_email
          else
            @tire_store.contact_email = current_user.email
          end
          @tire_store.name = @account.name

          @tire_store.affiliate_referrer = @account.affiliate_referrer
          @tire_store.affiliate_time = @account.affiliate_time
          @tire_store.affiliate_id = @account.affiliate_id

          if params[:type] && params[:type].downcase == 'private'
            @tire_store.private_seller = true
            if params[:hide_phone] == 'yes'
              @tire_store.hide_phone = true
            else
              @tire_store.hide_phone = params[:hide_phone]
            end
          end

          @tire_store.account_id = @account.id
          @tire_store.domain = params[:domain]

          puts "Saving tirestore..."
          if !@tire_store.save
            @tire_store.errors.each do |e|
              puts "#{e.to_s}"
            end
          end

          if (!params[:type].nil? && params[:type].downcase != 'private')
            # 04/22/13 Send the 'welcome' email
            OnBoardMailer.delay.on_board_email(current_user)
          else
            OnBoardMailer.delay.on_board_email_private_seller(current_user)
          end
        else
          puts "Skipping tirestore: #{params[:createStore]}-#{params[:type]}"
        end

        if current_user && current_user.account.nil?
          current_user.update_attribute(:account_id, @account.id)
          current_user.update_attribute(:admin, 1)
          sign_in current_user
        end

        if !params[:type].nil?
          if params[:type].downcase == "platinum"
              if create_contracts
              # let's create a contract for this user.  It will tie to the "free" plan.
              @account.create_free_trial_contract()

              # now create a regular contract that will begin when the free trial expires
              @account.create_platinum_contract()
            end
          elsif params[:type].downcase == "silver"
            if create_contracts
              # now create a regular contract that will begin when the free trial expires
              @account.create_silver_contract()
            end
          elsif params[:type].downcase == "gold"
            if create_contracts
              # now create a regular contract that will begin when the free trial expires
              @account.create_gold_contract()
            end
          end
        end

        if !@tire_store.nil?
          if collect_cc_upfront
            if secure_cc
              format.html { redirect_to :action => "cc_info", :tire_store_id => @tire_store.id, :controller => :pages, :protocol => 'https://' }
            else
              format.html { redirect_to :action => "cc_info", :tire_store_id => @tire_store.id, :controller => :pages }
            end   
          else
            # format.html { redirect_to @tire_store, notice: 'Congratulations - you are ready to list your tires!' }
            if !params[:new].nil?
              @href = "/new_multiple?tire_store_id=#{@tire_store.id}"
              format.html { redirect_to @href, notice: 'Congratulations - you are ready to list your tires!' }
            elsif !params[:used].nil?
              @href = "/generic_tire_listings/new?tire_store_id=#{@tire_store.id}"
              format.html { redirect_to @href, notice: 'Congratulations - you are ready to list your tires!' }
            else
              format.html { redirect_to @tire_store, notice: 'Congratulations - you are ready to list your tires!' }
            end
          end
        end

        format.html { redirect_to @account, notice: 'Account was successfully created.' }
        format.json { render json: @account, status: :created, location: @account }
      else
        if params[:type] && params[:type].downcase == 'private'
          @private_seller = true
        end
        format.html { render action: "new" }
        #format.html { redirect_to new_account_path(@account, :type => params[:type]) }
        format.json { render json: @account.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /accounts/1
  # PUT /accounts/1.json
  def update
    @account = Account.find(params[:id])

    respond_to do |format|
      if @account.update_attributes(params[:account])
        format.html { redirect_to :back, notice: 'Account was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @account.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /accounts/1
  # DELETE /accounts/1.json
  def destroy
    @account = Account.find(params[:id])
    @account.destroy

    respond_to do |format|
      format.html { redirect_to accounts_url }
      format.json { head :no_content }
    end
  end
end
