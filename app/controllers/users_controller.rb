class UsersController < ApplicationController
  ### KSI REIMPLEMENT before_filter :signed_in_user, only: [:edit, :update, :show]
before_filter :correct_user,   only: [:edit, :update, :show]

  # GET /users
  # GET /users.json
  def index
    if !super_user?
      redirect_to root_path, :alert => "You do not have access to that page."
      return
    end

    @users = User.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @users }
    end
  end  

  # GET /user/transfer/1.json
  def transfer
    @tire_store = TireStore.find(params[:id])
    respond_to do |format|
      format.json { render :json => @tire_store, :except => [:id, :created_at, :updated_at, :latitude, :longitude] }
    end
  end


  # GET /user/transfer/1.json
  def transfer
    @tire_store = TireStore.find(params[:id])
    respond_to do |format|
      format.json { render :json => @tire_store, :except => [:id, :created_at, :updated_at, :latitude, :longitude] }
    end
  end


  # GET /users/1
  # GET /users/1.json
  def show
    @user = User.find(params[:id])
    @reservations = @user.reservations.paginate(page: params[:page])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @user }
    end
  end

  # GET /users/new
  # GET /users/new.json
  def new
    @user = User.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @user }
    end
  end

  # GET /users/1/edit
  def edit
    @user = User.find(params[:id])
  end

  # POST /users
  # POST /users.json
  def create
    @user = User.new(params[:user])

    if !request.env['affiliate.tag'].nil?
      aff_id = request.env['affiliate.tag'].to_s
      if aff_id.length > 0
        @affiliate = Affiliate.find_by_affiliate_tag(aff_id)
        if !@affiliate.nil?
          begin
            @user.affiliate_id = @affiliate.id
            @user.affiliate_time = Time.at(env['affiliate.time']) unless request.env['affiliate.time'].nil?
            @user.affiliate_referrer = request.env['affiliate.from'] unless request.env['affiliate.from'].nil?
          rescue
            # not going to worry about it...
          end
        end
      end
    end

    respond_to do |format|
      if @user.save
        sign_in @user

        if @user.is_tireseller?
          format.html { redirect_to pages_pricing_url }
          format.json { render json: @user, status: :created, location: @user }
        else
          format.html { redirect_to @user, notice: 'User was successfully created.' }
          format.json { render json: @user, status: :created, location: @user }
        end
      else
        format.html { render action: "new" }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /users/1
  # PUT /users/1.json
  def update
    @user = User.find(params[:id])
    if @user.update_attributes(params[:user])
      @user.save 
      
      flash[:success] = "Profile updated"
      sign_in @user
      redirect_to @user
    else
      @user.errors.each do |e, r|
        puts "Error: #{e} - #{r}"
      end
      render 'edit'
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user = User.find(params[:id])
    @user.destroy

    respond_to do |format|
      format.html { redirect_to users_url }
      format.json { head :no_content }
    end
  end

  private
    def signed_in_user
      unless signed_in?
        store_location
        redirect_to signin_path, notice: "Please sign in."
      end
    end
  
    def correct_user
      @user = User.find(params[:id])
      if !current_user?(@user) && !super_user?
        redirect_to root_path, :alert => "You do not have access to that page." 
      end
    end

end
