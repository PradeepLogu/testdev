class PromotionsController < ApplicationController
  include PromotionsHelper
  before_filter :has_promotion_access, :except => [:deals, :show]

  def create_tiered_promotion
    promo_name = params[:promo_name]
    start_date = (params[:start_date]["start_date(1i)"] + '-' + params[:start_date]["start_date(2i)"] + '-' + params[:start_date]["start_date(3i)"]).to_date
    end_date = (params[:end_date]["end_date(1i)"] + '-' + params[:end_date]["end_date(2i)"] + '-' + params[:end_date]["end_date(3i)"]).to_date
    description = params[:description]
    promotion_type = params[:promotion_type]
    tire_store_ids = {} # TODO - add options for this
    promo_url = params[:promo_url]
    if super_user?
      promo_level = params[:promo_level]
    else
      promo_level = "A"
    end
    new_or_used = params[:new_or_used]

    website = params[:promo_url]
    promo_image = params[:promo_image]
    attachment = params[:promo_attachment]

    ar = params[:tire_manufacturer]

    new_promos = []

    p = nil

    ar.each do |a|
      if a.class.name == "String"
        p = Promotion.new
        p.tire_manufacturer_id = a.to_i
        p.promo_name = promo_name
        p.description = description
        p.promotion_type = promotion_type
        p.tire_store_ids = tire_store_ids
        p.promo_url = promo_url
        p.promo_level = promo_level
        p.start_date = start_date
        p.end_date = end_date
        p.new_or_used = new_or_used
        p.promo_attachment = attachment
        p.promo_image = promo_image
        p.promo_url = website

        if promo_level == "N"
          # national promotion
        elsif promo_level == "D"
          # distributor level promotion - not yet supported
        elsif promo_level == "A"
          p.account_id = current_user.account_id
        end

        new_promos << p
      else
        # should be a hash with all the values for this manufacturer
        a.each do |h|
          case h[0]
          when "(min_rebate)"
            p.promo_amount_min = h[1] if promotion_type == "R"
          when "(max_rebate)"
            p.promo_amount_max = h[1] if promotion_type == "R"
          when "(percent)"
            p.promo_amount_min = h[1] if promotion_type == "P"
          when "(amount)"
            p.promo_amount_min = h[1] if promotion_type == "D"
          when "(special_price)"
            p.promo_amount_min = h[1] if promotion_type == "S"
          when "(tire_model)"
            tm = TireModelInfo.find_by_tire_manufacturer_id_and_tire_model_name(p.tire_manufacturer_id, h[1])
            if !tm
              # let's validate that this is a legimate manu/name combo
              t = TireModel.find_all_by_tire_manufacturer_id_and_name(p.tire_manufacturer_id, h[1]).first
              if t
                # create the TMI
                tm = TireModelInfo.find_or_create_by_tire_manufacturer_id_and_tire_model_name(p.tire_manufacturer_id, h[1])
              end
            end
            p.add_tire_model_info_id_to_promotion(tm.id) if tm
          end
        end
      end
    end
    uuid = nil
    @promotions = []
    new_promos.each do |x|
      x.uuid = uuid
      x.save
      uuid = x.uuid
      @promotions << x
    end

    respond_to do |format|
      # format.html { render action: "show" }
      if !@promotions.first.new_record?
        @url = "/promotions/#{@promotions.first.id}"
        puts "going to #{@url}"
        redirect_to @url, notice: 'Promotion was successfully created.'
        return
      else
        puts "fail"
        flash.now[:notice] = "Post can not be saved, please enter information."
        redirect_to '/create_promotion'
        return
      end
    end
  end

  def create
  end

  def new
    @tire_manufacturers = TireManufacturer.find(:all, :order => 'name')
  end

  def edit
  end

  def show
    if !@promotions
      @promotions = []
      promotion = Promotion.find(params[:id])
      if promotion
        @promotions << Promotion.find_all_by_uuid(promotion.uuid, :order => :id)
        @master_promotion = @promotions.first.first
        @tire_store = @master_promotion.nearest_tire_store(session[:location], 50)
      end
    end
  end

  def update
  end

  def tire_listing
    @tire_listing = TireListing.find_by_id(params[:id])
    if !@tire_listing
      render :text => 'Unable to find promotion'
    else
      @promotions = []
      @tire_listing.eligible_promotions.each do |p|
        @promotions << Promotion.find_all_by_uuid(p.uuid)
      end
      render :partial => 'promotion'
    end
  end

  def new_tier
    @x = params[:x].to_i + 1
    @tire_manufacturers = TireManufacturer.find(:all, :order => 'name')
    respond_to do |format|
      format.js
    end
  end

  def index
    if params[:type]
      if params[:type].downcase == "national"
        @promotions = Promotion.national_promotions || []
      elsif params[:type].downcase == "treadhunter"
        if session[:location] && !session[:location].blank?
          @promotions = Promotion.local_promotions(session[:location], 50, 25, ['D', 'O', 'P', 'S', 'T']) || []
        else
          @promotions = Promotion.local_promotions("Atlanta, GA", 50, 25, ['D', 'O', 'P', 'S', 'T']) || []
        end
      elsif params[:type].downcase == "local"
        if session[:location] && !session[:location].blank?
          @promotions = Promotion.local_promotions(session[:location], 50, 25) || []
        else
          @promotions = Promotion.local_promotions("Atlanta, GA", 50, 25) || []
        end
      else
        @promotions = Promotion.where("end_date >= '#{Date.today}'")
      end
    else
      @promotions = Promotion.where("end_date >= '#{Date.today}'")
    end
    @promo_title = "Promotions"
  end

  def deals_old
    @local_deals = Promotion.all()#.where(:promo_level => "N") || []
    @national_deals = Promotion.where(:promo_level => "D") || []
    @treadhunter_deals = Promotion.where(:promo_level => "T") || []
  end

  def deals
    if session[:location] && !session[:location].blank?
      @local_deals = Promotion.local_promotions(session[:location], 50, 25) || []
      @national_deals = Promotion.national_promotions || []
      @treadhunter_deals = Promotion.local_promotions(session[:location], 50, 25, ['D', 'O', 'P', 'S', 'T']) || []
    else
      @local_deals = Promotion.local_promotions("Atlanta, GA", 50, 25) || []
      @national_deals = Promotion.national_promotions || []
      @treadhunter_deals = Promotion.local_promotions("Atlanta, GA", 50, 25, ['D', 'O', 'P', 'S', 'T']) || []
    end
  end
end
