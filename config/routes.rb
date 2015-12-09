TireDev::Application.routes.draw do

  get "learning_center/index"
  get "promotions/index"

  get '/search', to: 'browse_tires#search', as: :search_page

  get "/states", to: "browse_tires#states"
  get "/states/:state", to: "browse_tires#cities_in_state"
  #get "/states/:state/:city", to: "tire_stores#stores_by_location"

  get "/car_type", to: "browse_tires#car_type"
  get "/car_make/:type", to: "browse_tires#car_make"
  get "/car_model/:make", to: "browse_tires#car_model"
  get "/car_year/:model", to: "browse_tires#car_year"
  get "/car_version/:year", to: "browse_tires#car_option"
  #get "/car_type/:type", to: "browse_tires#car_make"
  #get "/car_type/:type/:make", to: "browse_tires#car_model", as: :models_by_car_make
  #get "/car_type/:type/:make/:model", to: "browse_tires#car_year", as: :years_by_car_model
  #get "/car_type/:type/:make/:model/:year", to: "browse_tires#car_option", as: :options_by_car_year

  get '/tire_size', to: 'browse_tires#tire_wheeldiameter'
  get '/tire_size/:wheeldiameter', to: 'browse_tires#tire_width'
  get '/tire_size/:wheeldiameter/:diameter', to: 'browse_tires#tire_ratio'

  get '/brands', to: 'model_searches#index'
  get '/brands/:brand_id', to: 'model_searches#showbrand'
  get '/brands/models/:model_id', to: 'model_searches#showmodel', as: :show_tire_model
  get '/brands/:brand_id/categories/:category_id', to: 'model_searches#category_results', as: :models_by_tire_category



  get '/assets/fonts/:font.:ext', to: redirect('/assets/%{font}.%{ext}')
  get '/fonts/:font.:ext', to: redirect('/assets/%{font}.%{ext}')
  get '/images/:img.:ext', to: redirect('/assets/%{img}.%{ext}')

  #resource :devices do
  #  post do
  #    @device = Device.create(user: current_user, token: params[:token], platform: params[:platform])
  #    present @device, with: WellWithMe::Entities::Device
  #  end
  #end

  #resource :tire_store_markups do
  #  post :edit_multiple, :controller => 'tire_store_markups'
  #  put :update_multiple, :controller => 'tire_store_markups'
  #end

  match "/tire_store_markups/edit_multiple" => "tire_store_markups#edit_multiple"

  resource :devices do
    get 'register_device', :controller => 'devices'
    post 'update_device', :controller => 'devices'
  end

  resources :appointments, only: [:new, :create]
  #resource :appointments do
  #  get 'list'
  #end

  resources :generic_tire_listings, only: [:new, :create, :destroy, :update, :edit]
  resource :generic_tire_listings do
    get 'get_sizes_for_wheeldiameter'
  end

  resource :promotions do
    post 'create_tiered_promotion', :controller => 'promotions'
    get 'create_tiered_promotion', :controller => 'promotions'
    get 'create', :controller => 'promotions'
    get 'update', :controller => 'promotions'
    get 'new_tier', :controller => 'promotions'
  end

  resource :tire_stores_distributors do
    get 'edit', :controller => 'tire_stores_distributors'
    get 'show', :controller => 'tire_stores_distributors'
  end

  match '/team' => 'pages#team'
  match '/clean_test_data' => 'pages#clean_test_data'
  match '/pages/home_tb' => 'pages#home_tb'
  match '/pages/sales_charts' => 'pages#sales_charts'
  match '/ecomm_sample' => 'pages#ecomm_sample'
  match '/order/complete' => 'pages#complete_order', :via => [:post]
  match '/order/create' => 'pages#create_order', :via => [:post]

  match 'appointments/confirm' => 'appointments#confirm_appointments'
  match 'appointments/ajax_appointment' => 'appointments#ajax_appointment'
  match 'appointments/ajax_order_details' => 'appointments#ajax_order_details'
  match 'appointments/confirm_primary' => 'appointments#confirm_primary'
  match 'appointments/confirm_secondary' => 'appointments#confirm_secondary'
  match 'appointments/deny_appointment' => 'appointments#deny_appointment'
  match 'appointments/html_appointments_by_day' => 'appointments#html_appointments_by_day'

  match 'ajax/ajax_promotion_details' => 'ajax#ajax_promotion_details'
  match 'ajax/get_store_from_phone_and_zip' => 'ajax#get_store_from_phone_and_zip'

  match '/get_financial_data' => 'pages#get_financial_data', :via => [:get, :post]

  match 'create_promotion' => 'promotions#new'
  match 'new_promo_tier' => 'promotions#new_tier'
  match 'create_tiered_promotion' => 'promotions#create_tiered_promotion'

  match '/tire-stores/:tire_store_id/promotions' => 'tire_stores#promotions'
  match '/tire_stores/:tire_store_id/promotions' => 'tire_stores#promotions'

  match '/tire-stores/location/:city/:state' => 'tire_stores#stores_by_location'
  match '/tire-stores/location/:zipcode' => 'tire_stores#stores_by_location'

  match 'promotions/tire-listing/:id' => 'promotions#tire_listing'
  match 'promotions/:id' => 'promotions#show'
  match 'deals' => 'promotions#deals'
  
  resource :learning_center, :controller => :learning_center do
    get 'show', :action => 'index'
    get 'faq', :action => 'faq'
    get 'glossary', :action => 'glossary'
    get 'tire_size', :action => 'tire_size'
  end


  get "password_resets/new"

  match '', to: 'tire_stores#show', :constraints => lambda { |r| r.subdomain.present? && r.subdomain != "www" && r.subdomain != "beta" }
  match '/information', to: 'tire_stores#information', :constraints => lambda { |r| r.subdomain.present? && r.subdomain != "www" && r.subdomain != "beta" }
  match '/our-tires', to: 'tire_stores#ourtires', :constraints => lambda { |r| r.subdomain.present? && r.subdomain != "www" && r.subdomain != "beta" }
  match '/store', to: 'tire_stores#store', :constraints => lambda { |r| r.subdomain.present? && r.subdomain != "www" && r.subdomain != "beta" }
  match '/info1', to: 'tire_stores#info1', :constraints => lambda { |r| r.subdomain.present? && r.subdomain != "www" && r.subdomain != "beta" }
  match '/info2', to: 'tire_stores#info2', :constraints => lambda { |r| r.subdomain.present? && r.subdomain != "www" && r.subdomain != "beta" }
  match '/info3', to: 'tire_stores#info3', :constraints => lambda { |r| r.subdomain.present? && r.subdomain != "www" && r.subdomain != "beta" }
  match '/info4', to: 'tire_stores#info4', :constraints => lambda { |r| r.subdomain.present? && r.subdomain != "www" && r.subdomain != "beta" }
  match '/info5', to: 'tire_stores#info5', :constraints => lambda { |r| r.subdomain.present? && r.subdomain != "www" && r.subdomain != "beta" }
  match '/tire_stores', to: 'tire_stores#index', :via => :get

  resources :contracts

  resources :assets, :only => [:edit, :create]

  resources :tire_model_infos

  match '/m/create_session/:base64_email/:base64_password', :to => 'sessions#mobile_create', via: :get

  match '/m/:base64_email/create_test_notifications_android.:format', :to => 'mobile#create_test_notifications_android', via: :get

  match '/m/show_notification/:device/:tire_store_id/:base64_email/:token/:guid.:format', :to => 'mobile#show_notification', via: :get

  match '/m/tire_stores/:token/:latitude/:longitude/:searchstr.:format', :to => 'mobile#find_stores', via: :get
  match '/m/tire_store/:tire_store_id.:format', :to => 'mobile#find_store', via: :get
  match '/m/:latitude/:longitude/promotions.:format', :to => 'mobile#find_promotions', via: :get
  match '/m/:latitude/:longitude/s_tire_stores.:format', :to => 'mobile#find_scraped_stores', via: :get
  match '/m/:latitude/:longitude/tire_stores_list.:format', :to => 'mobile#combine_stores_for_list', via: :get
  match '/m/:latitude/:longitude/nonnationalpromotions.:format', :to => 'mobile#find_non_national_promotions', via: :get
  match '/m/tire_store/promotions/:tire_store_id.:format', :to => 'mobile#find_promotions_for_store', via: :get
  match '/m/:token/price_quote/:tire_store_id/:tire_model_id.:format', :to => 'mobile#realtime_price_quote', via: :get
  match '/m/:token/load_reservation/:tire_store_id/:reservation_id.:format', :to => 'mobile#load_reservation', via: :get
  match '/m/:token/:tire_store_id/order/:order_id.:format', :to => 'mobile#store_order', via: :get

  match '/m/:token/:tire_store_id/reservations.:format', :to => 'mobile#reservations', via: :get
  match '/m/:token/:tire_store_id/tire_listings.:format', :to => 'mobile#tire_listings', via: :get
  match '/m/tire_listing/:id.:format', :to => 'mobile#tire_listing', via: :get
  match '/m/:token/:tire_store_id/create_tire_listing.:format', :to => 'mobile#create_tire_listing', via: :post
  match '/m/:token/:tire_store_id/update_tire_listing/:id.:format', :to => 'mobile#update_tire_listing'
  match '/m/:token/:tire_store_id/update_tire_listing_photo/:photo/:id.:format', :to => 'mobile#update_tire_listing_photo'
  match '/m/:token/:tire_store_id/update_tire_listing_droid/:id.:format', :to => 'mobile#update_tire_listing_droid'
  match '/m/:token/:tire_store_id/delete_reservation/:id.:format', :to => 'mobile#delete_reservation'#, via: :delete
  match '/m/:token/:tire_store_id/delete_tire_listing/:id.:format', :to => 'mobile#delete_tire_listing'

  match '/m/:token/:tire_store_id/appointments/:reference_date.:format', :to => 'mobile#tire_store_appointments'
  match '/m/:token/:tire_store_id/appointments_range/:days_ahead/:reference_date.:format', :to => 'mobile#tire_store_appointments_range'

  match '/m/test_post.:format', :to => 'tire_listings#test_post', via: :post

  match '/m/:token/load_appointment/:appt_id.:format', :to => 'mobile#load_appointment'
  match '/m/:token/confirm_appointment_primary/:appt_id.:format', :to => 'mobile#confirm_appointment_primary', via: :post
  match '/m/:token/confirm_appointment_secondary/:appt_id.:format', :to => 'mobile#confirm_appointment_secondary', via: :post
  match '/m/:token/reject_appointment/:appt_id.:format', :to => 'mobile#reject_appointment', via: :post

  match '/m/:token/cl_template/:tire_listing_id.:format', :to => 'mobile#cl_template'

  match '/m/:token/store_order_stats/:tire_store_id.:format', :to => 'mobile#store_order_stats'

  match '/m/:token/:encoded_email/create_store.:format', :to => 'mobile#create_store'#, via: :post

  match '/tire_sizes/diameters.:format', :to => 'tire_sizes#diameters', via: :get
  match '/tire_sizes/diameters/:diameter/ratios.:format', :to => 'tire_sizes#ratios', via: :get
  match '/tire_sizes/diameters/:diameter/ratios/:ratio/wheeldiameters.:format', :to => 'tire_sizes#wheeldiameters', via: :get

  match '/tire_manufacturers/:manufacturer_name/:diameter/:ratio/:wheeldiameter/tire_models.:format', :to => 'tire_manufacturers#models_by_size'
  match '/tire_manufacturers/:manufacturer_name/:diameter/:ratio/:wheeldiameter/tire_model/:model_name.:format', :to => 'tire_manufacturers#model_lookup'
  match '/tire_manufacturers/index.:format', :to => 'tire_manufacturers#index'
  match '/m/widths.:format', :to => 'mobile#widths'
  match '/m/ratios.:format', :to => 'mobile#ratios'
  match '/m/tire_sizes.:format', :to => 'mobile#tire_sizes'
  match '/m/wheel_diameters.:format', :to => 'mobile#wheel_diameters'

  match '/m/register_user.:format', :to => 'mobile#register_user', :via => :post

  match '/storefront/:tire_store_id/edit', :to => 'brandings#edit', :as => 'branding'
  match '/storefront/:tire_store_id/update', :to => 'brandings#update'

  match '/images/:tire_store_id/edit', :to => 'assets#edit'
  #match '/assets/:tire_store_id/update', :to => 'assets#update'
  #resource :assets do
  #  post 'assets', :controller => 'assets'
  #  put 'assets', :controller => 'assets'
  #end

  match '/cl_templates/:tire_store_id/edit', :to => 'cl_templates#edit', :as => 'cl_template'
  match '/cl_template/:tire_store_id/update', :to => 'cl_templates#update'


  match '/tire_stores/:id', :to => 'tire_stores#show', via: :post
  match '/welcome/register/:uuid', :to => 'welcome#register'

  resource :welcome do
    #get 'register/:uuid', :controller => 'welcome'
    get 'no_record', :controller => 'welcome'
    post 'registration', :controller => 'welcome'
    get 'set_markups', :controller => 'welcome'
    get 'connect_with_stripe', :controller => 'welcome'
    post 'update_stripe', :controller => 'welcome'
    get 'registration_complete', :controller => 'welcome'
  end

  resource :installation_costs do
    get 'edit'
    post 'update_prices'
    get 'show_install_prices'
  end

  resource :tire_searches do
    post 'update_years', :controller => 'tire_searches'
    post 'update_models', :controller => 'tire_searches'
    post 'update_options', :controller => 'tire_searches'
    post 'update_wheeldiameters', :controller => 'tire_searches'
    post 'update_ratios', :controller => 'tire_searches'
    post 'destroy', :controller => 'tire_searches'
    post 'tireresults', :controller => 'tire_searches'
    get 'tireresults', :controller => 'tire_searches'
    get 'searchresults', :controller => 'tire_searches'
    post 'storeresults', :controller => 'tire_searches'
    get 'storeresults', :controller => 'tire_searches'
  end

  resource :ajax do
    get 'update_hours_for_store', :controller => 'ajax'
    get 'update_auto_models', :controller => 'ajax'
    get 'update_auto_models_visfire', :controller => 'ajax'
    get 'update_auto_years', :controller => 'ajax'
    get 'update_auto_years_visfire', :controller => 'ajax'
    get 'update_auto_options', :controller => 'ajax'
    get 'update_auto_options_visfire', :controller => 'ajax'
    get 'update_tire_ratios', :controller => 'ajax'
    get 'update_tire_ratios_visfire', :controller => 'ajax'
    get 'update_tire_wheeldiameters', :controller => 'ajax'
    get 'update_tire_wheeldiameters_visfire', :controller => 'ajax'
    get 'update_tire_manufacturers', :controller => 'ajax'
    get 'update_tire_manufacturers_visfire', :controller => 'ajax'
    get 'update_tire_models', :controller => 'ajax'
    get 'update_tire_models_no_size', :controller => 'ajax'
    get 'update_tire_models_visfire', :controller => 'ajax'
    get 'get_sizes_for_model', :controller => 'ajax'
    get 'get_models_for_tire_size', :controller => 'ajax'
    get 'update_tire_model_checkboxes', :controller => 'ajax'
    get 'build_store_placeholder', :controller => 'ajax'
    get 'validate_size_str', :controller => 'ajax'
    get 'load_storelisting_records', :controller => 'ajax'
    get 'load_tiresearch_records', :controller => 'ajax'
    get 'load_tiresearch_stores', :controller => 'ajax'
    get 'load_manufacturer_models', :controller => 'ajax'
    get 'register_for_newsletter', :controller => 'ajax'
    get 'new_notifications', :controller => 'ajax'
    get 'appointments_table', :controller => 'ajax'
    get 'listings_table', :controller => 'ajax'
    get 'promotions_table', :controller => 'ajax'
    get 'searches_table', :controller => 'ajax'
    get 'stores_table', :controller => 'ajax'
    get 'users_table', :controller => 'ajax'
    get 'edit_store', :controller => 'ajax'
    get 'get_checkout_info', :controller => 'ajax'
    get 'create_appointment', :controller => 'ajax'
    get 'create_order', :controller => 'ajax'
    get 'homepage_foursquare_reviews', :controller => 'ajax'
    get 'homepage_local_promotions', :controller => 'ajax'
    get 'homepage_yelp_reviews', :controller => 'ajax'
    get 'homepage_yelp_reviews_no_location', :controller => 'ajax'
    get 'homepage_foursquare_reviews_no_location', :controller => 'ajax'
    get 'homepage_google_reviews', :controller => 'ajax'
    get 'homepage_google_reviews_no_location', :controller => 'ajax'
    get 'homepage_cities_by_region', :controller => 'ajax'
    get 'homepage_cities_by_state', :controller => 'ajax'
    get 'display_faq_category', :controller => 'ajax'
    get 'cancel_order', :controller => 'ajax'
  end

  resource :pages do
    post 'tireseller_create', :controller => 'pages'
    get 'get_financial_data', :controller => 'pages'
    post 'get_financial_data', :controller => 'pages'
    get 'account_survey', :controller => 'pages'
    get 'account_thank_you', :controller => 'pages'
    get 'mobile_chart_data', :controller => 'pages'
    get 'mobile_store_data', :controller => 'pages'
    get 'traffic_data', :controller => 'pages'
    get 'affiliate_data', :controller => 'pages'
    get 'mobile_impressions_data', :controller => 'pages'
    get 'sources_data', :controller => 'pages'
    get 'visits_data', :controller => 'pages'
    get 'month_states_data', :controller => 'pages'
    get 'week_states_data', :controller => 'pages'
    get 'day_states_data', :controller => 'pages'
    get 'blank', :controller => 'pages' if Rails.env.development?
  end

  resource :tire_stores do
    get 'show_information', :controller => 'tire_stores'
    get 'stats', :controller => 'tire_stores'
    post 'update_colors', :controller => 'tire_stores'
    get 'inventory_report_selector', :controller => 'tire_stores'
    post 'inventory_report', :controller => 'tire_stores'
    get 'set_place_id', :controller =>  'tire_stores'
    get 'write_review', :controller => 'tire_stores'
    get 'upgrade_to_premium', :controller => 'tire_stores'
  end

  resources :reservations
  #resources :auto_manufacturers
  #resources :auto_models
  #resources :auto_options
  #resources :tires
  #resources :auto_years
  resources :tire_stores
  #resources :tire_sizes
  resources :tire_searches
  #resources :tire_manufacturers
  resources :tire_listings
  resources :accounts
  resources :users
  resources :sessions, only: [:new, :create, :destroy]
  resources "tire-listings", :as => :tire_listings
  resources "tire-stores", :as => :tire_stores
  resources "tire-searches", :as => :tire_searches
  resources :contact_us, :only => [:new, :create]
  #resources :contact_sellers, :only => [:new, :create], :via => [:get, :post]
  match '/contact_seller', :to => 'contact_sellers#create', via: :post


  get "pages/xyzzy_abcdef"
  get "pages/home"
  get "pages/search"
  get "pages/about"
  get "pages/contact"
  get "pages/tireresults"
  get "pages/pricing"
  get "pages/tireseller_home"
  get "pages/tireseller_home_tabs"
  get "pages/cc_info"
  get "charges/cc_entered"
  get "pages/faq"
  get "pages/error"
  get "pages/find_tirestores"
  #post "pages/create_tirestore_spreadsheet"
  post 'create_tirestore_spreadsheet', :controller => 'pages'

  post 'tire_search/update_models'
  post 'tire_search/update_years'
  post 'tire_search/update_options'
  post 'tire_search/update_ratios'

  match '/transfer_from_prod/:tire_store_id.:format', :to => 'pages#transfer_from_prod'
  get '/tire_store/transfer/:id.:format', :to => 'tire_stores#transfer'
  get '/tire_store_branding/transfer/:id.:format', :to => 'tire_stores#transfer_branding'
  get '/account/transfer/:id.:format', :to => 'accounts#transfer'
  get '/tire_listings/transfer/:tire_store_id.:format', :to => 'tire_listings#transfer'
  get '/tire_listing/transfer/:id.:format', :to => 'tire_listings#transfer_single'
  get '/user/transfer/:id.:format', :to => 'users#transfer'
  get '/tire_listing/transfer.json', :to => 'tire_listings#transfer'
  get '/tire_listings/external_site/:id', :to => 'tire_listings#external_site'

  match '/', :to => 'pages#home_visfire' # :to => 'pages#newhome' #'pages#index' # 'pages#home'
  match '/index', :to => 'pages#home_visfire'
  match '/home', :to => 'pages#home'
  match '/partners', :to => 'pages#partners'
  match '/ut_landing', :to => 'pages#ut_landing'
  match '/nt_landing', :to => 'pages#nt_landing'
  match '/th_landing', :to => 'pages#th_landing'
  match '/th_unified', :to => 'pages#th_unified', via: :post
  match '/ut_help', :to => 'pages#ut_help'
  match '/search', :to => 'pages#search'
  match '/about', :to => 'pages#about'
  match '/tireresults', :to => 'pages#tireresults'
  match '/searchresults', :to => 'pages#searchresults'
  match '/signup',  to: 'users#new'
  match '/signin',  to: 'sessions#new'
  match '/signout', to: 'sessions#destroy', via: :delete
  match '/registration_success', to: 'pages#registration_success', via: :get
  match '/set_store_type', to: 'pages#set_store_type', via: :post
  match '/set_seller_type', to: 'pages#set_seller_type', via: [:post, :get]
  match '/defaultDescription', to: 'tire_listings#defaultDescription'
  match '/privacy', to: 'pages#privacy'
  match '/myTreadHunter', to: 'pages#tireseller_home_tabs'
  match '/tireseller_registration', to: 'pages#th_landing' #pages#tireseller_registration'
  match '/saved_searches', to: 'tire_searches#saved_searches'
  match '/mobile_support_seller', to: 'pages#mobile_support_seller'
  match '/mobile_support_buyer', to: 'pages#mobile_support_buyer'
  match '/home_visfire', to: 'pages#home_visfire'
  match '/home_unified', to: 'pages#home_unified'
  match '/th_data', to: 'pages#th_data'
  match '/th_city_data', to: 'pages#th_city_data'
  match '/deals', to: 'deals#show'

  resource :tire_listings do
    post 'tire_size_selected', :controller => 'tire_listings'
    post 'tire_model_selected', :controller => 'tire_listings'
    post 'get_sizes_for_model', :controller => 'tire_listings'
    get  'tire_model_selected', :controller => 'tire_listings'
    post 'tire_manufacturer_selected', :controller => 'tire_listings'
  end

  match '/tire_listings/new.json', :to => 'tire_listings#create'
  match '/tire_listings/:id.json', :to => 'tire_listings#update'
  match '/tire_listings/:id.html', :to => 'tire_listings#update'
  match '/new_multiple', :to => 'tire_listings#new_multiple'
  match '/create_multiple', :to => 'tire_listings#create_multiple'

  match '/tire_listings/ajax/:id', :to => 'tire_listings#ajax'

  match '/accounts/use/:id', :to => 'accounts#use'

  match '/tire-store/:tire_store_id/tire-listings.:format', :to => 'mobile#store_listings'
  match '/tire-store/:tire_store_id/:search_filter/tire-listings.:format', :to => 'mobile#store_listings'
  match '/branding/:tire_store_id.:format', :to => 'mobile#branding'

  match '/m/auto_manufacturers.:format', :to => 'mobile#auto_manufacturers'
  match '/m/auto_models/:auto_manufacturer_id.:format', :to => 'mobile#auto_models'
  match '/m/auto_years/:auto_model_id.:format', :to => 'mobile#auto_years'
  match '/m/auto_options/:auto_year_id.:format', :to => 'mobile#auto_options'
  match '/m/:make/:model/:year/:option/find_size.:format', :to => 'mobile#find_size', :option => /([^\/])+?/, :model => /([^\/])+?/

  root :to => 'pages#home'

  # this is for json stuff, mobile communication
  match ':controller/:action/:id.:format'

  # image folder for bootstrap
  get "/img/:filename.:ext" => redirect("/assets/%{filename}.%{ext}")

  match "/sitemap.xml", :to => "sitemap#index", :defaults => {:format => :xml}
  match "/tirelistings.xml", :to => "sitemap#tirelistings", :defaults => {:format => :xml}
  match "/tirelistings:div.xml", :to => "sitemap#tirelistings_partial", :defaults => {:format => :xml}

  get "logout" => "sessions#destroy", :as => "logout"
  get "login" => "sessions#new", :as => "login"
  get "signup" => "users#new", :as => "signup"
  root :to => "home#index"
  resources :users
  resources :sessions
  resources :password_resets

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
