class SitemapController < ApplicationController

  NUM_FILES = 10

  def index
    @tire_stores = TireStore.find(:all, :conditions => ["private_seller = false"])
    @static_urls = ['/', tire_stores_path, '/pages/faq']
    @sitemap_urls = ['/tirelistings.xml']
    @base_url = "http://#{request.host_with_port}"
    headers['Content-Type'] = 'application/xml'
    respond_to do |format|
      format.xml
    end
  end

  def tirelistings
  	#@tire_listings = TireListing.all

    #@tire_listings = TireListing.includes(:tire_store, :tire_size, :tire_manufacturer, :tire_model, :tire_category).find(:all)

    @base_url = "http://#{request.host_with_port}"
    headers['Content-Type'] = 'application/xml'
    respond_to do |format|
      format.xml { render "tirelistings_index", :locals => {:@filecount => NUM_FILES}}
    end
  end

  def tirelistings_partial
    #@tire_listings = TireListing.all

    @tire_listings = TireListing.includes(:tire_store, :tire_size, :tire_manufacturer, :tire_model, :tire_category).find(:all, :conditions => ["id % ? = ?", NUM_FILES, params[:div]])

    @base_url = "http://#{request.host_with_port}"
    headers['Content-Type'] = 'application/xml'
    respond_to do |format|
      format.xml { render "tirelistings"}
    end
  end
end