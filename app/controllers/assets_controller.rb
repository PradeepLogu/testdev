class AssetsController < ApplicationController
  before_filter :is_super_user, only: [:show, :edit, :index]
    
#  def index
#    @assets = [] #Asset.all

#    respond_to do |format|
#      format.html # index.html.erb
#      format.json { render json: @assets.map{|asset| asset.to_jq_upload } }
#    end
#  end

#  def show
#    @asset = Asset.find(params[:id])

#    respond_to do |format|
#      format.html # show.html.erb
#      format.json { render json: @asset }
#    end
#  end

  def new
    @asset = Asset.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @asset }
    end
  end

  def edit
    @tire_store = TireStore.find(params[:tire_store_id])
    @branding = @tire_store.branding
    @assets = @branding.assets.order(:id)
  end

  def create
    @asset = Asset.new(params[:asset])

    respond_to do |format|
      if @asset.save
        format.html {
          render :json => [@asset.to_jq_upload].to_json,
          :content_type => 'text/html',
          :layout => false
        }
        format.json { render json: [@asset.to_jq_upload].to_json, status: :created, location: @asset }
      else
        format.html { render action: "new" }
        format.json { render json: @asset.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @asset = Asset.find(params[:id])

    # update usages
    @asset.valid_uses.each do |u|
      if params[:usage].include?(u)
        @asset.create_usage(u)
      else
        @asset.delete_usage(u)
      end
    end

    respond_to do |format|
      if @asset.update_attributes(params[:asset])
        format.html { redirect_to "/images/#{@asset.branding.tire_store_id}/edit", notice: 'Image was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { redirect_to "/images/#{@asset.branding.tire_store_id}/edit", notice: 'Image was successfully updated.' }
        format.json { render json: @asset.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @asset = Asset.find(params[:id])
    @asset.destroy

    respond_to do |format|
      format.html { redirect_to "/images/#{@asset.branding.tire_store_id}/edit", notice: 'Image was successfully updated.' }
      format.json { head :no_content }
    end
  end
end
