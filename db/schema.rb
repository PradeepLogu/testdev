# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20140110144854) do

  create_table "accounts", :force => true do |t|
    t.string   "name"
    t.string   "address1"
    t.string   "address2"
    t.string   "city"
    t.string   "state"
    t.string   "zipcode"
    t.string   "phone"
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
    t.string   "stripe_id"
    t.string   "billing_email"
    t.integer  "affiliate_id",       :default => -1, :null => false
    t.date     "affiliate_time"
    t.string   "affiliate_referrer"
  end

  create_table "affiliates", :force => true do |t|
    t.string   "name"
    t.string   "address"
    t.string   "city"
    t.string   "state"
    t.string   "zipcode"
    t.string   "affiliate_tag"
    t.string   "contact_name"
    t.string   "contact_email"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "asset_usages", :force => true do |t|
    t.integer  "tire_store_id"
    t.integer  "branding_id"
    t.integer  "asset_id"
    t.string   "usage_name"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "assets", :force => true do |t|
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
    t.integer  "branding_id"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
    t.string   "url"
    t.string   "caption"
  end

  create_table "auto_manufacturers", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "auto_models", :force => true do |t|
    t.string   "name"
    t.integer  "auto_manufacturer_id"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
  end

  create_table "auto_options", :force => true do |t|
    t.string   "name"
    t.integer  "auto_year_id"
    t.integer  "tire_size_id"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  create_table "auto_years", :force => true do |t|
    t.string   "modelyear"
    t.integer  "auto_model_id"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "brandings", :force => true do |t|
    t.integer  "tire_store_id"
    t.datetime "expiration_date"
    t.text     "listing_html"
    t.text     "store_html"
    t.datetime "created_at",                        :null => false
    t.datetime "updated_at",                        :null => false
    t.string   "logo_file_name"
    t.string   "logo_content_type"
    t.integer  "logo_file_size"
    t.datetime "logo_updated_at"
    t.string   "tab1title"
    t.text     "tab1content"
    t.string   "tab2title"
    t.text     "tab2content"
    t.string   "tab3title"
    t.text     "tab3content"
    t.string   "tab4title"
    t.text     "tab4content"
    t.string   "tab5title"
    t.text     "tab5content"
    t.string   "fb_page"
    t.string   "twitter"
    t.integer  "template_number",    :default => 1
    t.string   "slogan"
    t.string   "slogan_description"
    t.hstore   "properties"
  end

  add_index "brandings", ["properties"], :name => "brandings_properties"

  create_table "capabilities", :force => true do |t|
    t.string   "name"
    t.string   "key"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "cl_templates", :force => true do |t|
    t.integer  "tire_store_id",                               :default => 0
    t.integer  "account_id",                                  :default => 0
    t.string   "title"
    t.string   "body",                        :limit => 4096
    t.datetime "created_at",                                                 :null => false
    t.datetime "updated_at",                                                 :null => false
    t.string   "cl_email"
    t.string   "cl_password"
    t.string   "cl_posting_page"
    t.string   "cl_subarea"
    t.string   "cl_specific_location"
    t.string   "cl_login_page"
    t.string   "cl_logout_page"
    t.string   "cl_login_email_fieldname"
    t.string   "cl_login_password_fieldname"
    t.string   "cl_ad_name"
    t.string   "cl_ad_value"
    t.string   "cl_category_name"
    t.string   "cl_category_value"
    t.string   "cl_title_field"
    t.string   "cl_price_field"
    t.string   "cl_specific_location_field"
    t.text     "cl_actions"
    t.string   "title_new_listings"
    t.string   "body_new_listings",           :limit => 4096
  end

  create_table "contracts", :force => true do |t|
    t.integer  "account_id"
    t.date     "expiration_date"
    t.integer  "contract_amount"
    t.integer  "max_monthly_listings"
    t.datetime "created_at",                              :null => false
    t.datetime "updated_at",                              :null => false
    t.date     "start_date"
    t.integer  "plan_id"
    t.boolean  "active",               :default => false
    t.integer  "quantity",             :default => 1
    t.boolean  "bill_cc"
    t.integer  "billing_type"
    t.datetime "bill_date"
  end

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  create_table "distributors", :force => true do |t|
    t.string   "distributor_name"
    t.string   "address"
    t.string   "city"
    t.string   "state"
    t.string   "zipcode"
    t.string   "contact_name"
    t.string   "contact_email"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
    t.hstore   "tire_manufacturers"
  end

  create_table "generic_tire_listings", :force => true do |t|
    t.integer  "remaining_tread_min"
    t.integer  "remaining_tread_max"
    t.integer  "treadlife_min"
    t.integer  "treadlife_max"
    t.integer  "tire_store_id"
    t.integer  "quantity"
    t.boolean  "includes_mounting"
    t.integer  "warranty_days"
    t.hstore   "tire_sizes"
    t.string   "currency"
    t.integer  "price"
    t.integer  "mounting_price"
    t.datetime "created_at",          :null => false
    t.datetime "updated_at",          :null => false
  end

  create_table "impressions", :force => true do |t|
    t.string   "impressionable_type"
    t.integer  "impressionable_id"
    t.integer  "user_id"
    t.string   "controller_name"
    t.string   "action_name"
    t.string   "view_name"
    t.string   "request_hash"
    t.string   "ip_address"
    t.string   "session_hash"
    t.text     "message"
    t.text     "referrer"
    t.datetime "created_at",          :null => false
    t.datetime "updated_at",          :null => false
  end

  add_index "impressions", ["controller_name", "action_name", "ip_address"], :name => "controlleraction_ip_index"
  add_index "impressions", ["controller_name", "action_name", "request_hash"], :name => "controlleraction_request_index"
  add_index "impressions", ["controller_name", "action_name", "session_hash"], :name => "controlleraction_session_index"
  add_index "impressions", ["impressionable_type", "impressionable_id", "ip_address"], :name => "poly_ip_index"
  add_index "impressions", ["impressionable_type", "impressionable_id", "request_hash"], :name => "poly_request_index"
  add_index "impressions", ["impressionable_type", "impressionable_id", "session_hash"], :name => "poly_session_index"
  add_index "impressions", ["impressionable_type", "message", "impressionable_id"], :name => "impressionable_type_message_index"
  add_index "impressions", ["user_id"], :name => "index_impressions_on_user_id"

  create_table "notifications", :force => true do |t|
    t.integer  "user_id"
    t.integer  "account_id"
    t.boolean  "admin_only"
    t.boolean  "super_user_only"
    t.datetime "expiration_date"
    t.integer  "remaining_views"
    t.string   "message"
    t.string   "title"
    t.boolean  "sticky"
    t.integer  "visible_time"
    t.string   "image"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  add_index "notifications", ["account_id"], :name => "index_notifications_on_account_id"
  add_index "notifications", ["expiration_date"], :name => "index_notifications_on_expiration_date"
  add_index "notifications", ["user_id"], :name => "index_notifications_on_user_id"

  create_table "plan_capabilities", :force => true do |t|
    t.integer  "plan_id"
    t.integer  "capability_id"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "plans", :force => true do |t|
    t.string   "name"
    t.integer  "default_num_listings"
    t.string   "stripe_plan"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
  end

  create_table "promotions", :force => true do |t|
    t.string   "promotion_type"
    t.integer  "tire_manufacturer_id"
    t.hstore   "tire_model_infos"
    t.integer  "account_id"
    t.hstore   "tire_store_ids"
    t.date     "start_date"
    t.date     "end_date"
    t.text     "description"
    t.integer  "promo_type"
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
    t.string   "promo_attachment_file_name"
    t.string   "promo_attachment_content_type"
    t.integer  "promo_attachment_file_size"
    t.datetime "promo_attachment_updated_at"
    t.string   "promo_image_file_name"
    t.string   "promo_image_content_type"
    t.integer  "promo_image_file_size"
    t.datetime "promo_image_updated_at"
    t.string   "uuid"
    t.string   "promo_url"
    t.string   "promo_level"
    t.float    "promo_amount_min"
    t.float    "promo_amount_max"
    t.hstore   "tire_sizes"
    t.string   "promo_name"
    t.string   "new_or_used"
    t.string   "promotion_key"
  end

  add_index "promotions", ["tire_model_infos"], :name => "promotions_tire_model_infos"
  add_index "promotions", ["tire_sizes"], :name => "promotions_tire_size_ids"
  add_index "promotions", ["tire_store_ids"], :name => "promotions_tire_store_ids"

  create_table "redirect_rules", :force => true do |t|
    t.string   "source",                                      :null => false
    t.boolean  "source_is_regex",          :default => false, :null => false
    t.boolean  "source_is_case_sensitive", :default => false, :null => false
    t.string   "destination",                                 :null => false
    t.boolean  "active",                   :default => false
    t.datetime "created_at",                                  :null => false
    t.datetime "updated_at",                                  :null => false
  end

  add_index "redirect_rules", ["active"], :name => "index_redirect_rules_on_active"
  add_index "redirect_rules", ["source"], :name => "index_redirect_rules_on_source"
  add_index "redirect_rules", ["source_is_case_sensitive"], :name => "index_redirect_rules_on_source_is_case_sensitive"
  add_index "redirect_rules", ["source_is_regex"], :name => "index_redirect_rules_on_source_is_regex"

  create_table "request_environment_rules", :force => true do |t|
    t.integer  "redirect_rule_id",                                       :null => false
    t.string   "environment_key_name",                                   :null => false
    t.string   "environment_value",                                      :null => false
    t.boolean  "environment_value_is_regex",          :default => false, :null => false
    t.boolean  "environment_value_is_case_sensitive", :default => true,  :null => false
    t.datetime "created_at",                                             :null => false
    t.datetime "updated_at",                                             :null => false
  end

  add_index "request_environment_rules", ["redirect_rule_id"], :name => "index_request_environment_rules_on_redirect_rule_id"

  create_table "reservations", :force => true do |t|
    t.integer  "user_id"
    t.integer  "tire_listing_id"
    t.string   "buyer_email"
    t.string   "seller_email"
    t.string   "name"
    t.string   "address"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.string   "phone"
    t.datetime "expiration_date"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
    t.integer  "quantity"
    t.integer  "price"
    t.integer  "tire_manufacturer_id"
    t.integer  "tire_model_id"
    t.integer  "tire_size_id"
  end

  create_table "simple_captcha_data", :force => true do |t|
    t.string   "key",        :limit => 40
    t.string   "value",      :limit => 6
    t.datetime "created_at",               :null => false
    t.datetime "updated_at",               :null => false
  end

  add_index "simple_captcha_data", ["key"], :name => "idx_key"

  create_table "tire_categories", :force => true do |t|
    t.string   "category_name"
    t.string   "category_type"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "tire_listings", :force => true do |t|
    t.integer  "treadlife"
    t.integer  "price",                                                      :null => false
    t.integer  "status"
    t.string   "description",             :limit => 4096
    t.string   "teaser"
    t.integer  "tire_store_id"
    t.integer  "tire_size_id"
    t.float    "latitude"
    t.float    "longitude"
    t.datetime "created_at",                                                 :null => false
    t.datetime "updated_at",                                                 :null => false
    t.string   "source",                  :limit => 512
    t.integer  "tire_manufacturer_id"
    t.boolean  "includes_mounting"
    t.integer  "warranty_days"
    t.integer  "quantity"
    t.integer  "orig_cost"
    t.boolean  "crosspost_craigslist"
    t.string   "photo1_file_name"
    t.string   "photo1_content_type"
    t.integer  "photo1_file_size"
    t.datetime "photo1_updated_at"
    t.string   "photo2_file_name"
    t.string   "photo2_content_type"
    t.integer  "photo2_file_size"
    t.datetime "photo2_updated_at"
    t.string   "photo3_file_name"
    t.string   "photo3_content_type"
    t.integer  "photo3_file_size"
    t.datetime "photo3_updated_at"
    t.string   "photo4_file_name"
    t.string   "photo4_content_type"
    t.integer  "photo4_file_size"
    t.datetime "photo4_updated_at"
    t.integer  "tire_model_id"
    t.float    "remaining_tread"
    t.float    "original_tread"
    t.string   "currency",                                :default => "USD"
    t.boolean  "is_new",                                  :default => false
    t.date     "start_date"
    t.date     "expiration_date"
    t.string   "stock_number"
    t.boolean  "sell_as_set_only",                        :default => true
    t.string   "redirect_to"
    t.boolean  "is_generic",                              :default => false
    t.integer  "generic_tire_listing_id",                 :default => -1
  end

  add_index "tire_listings", ["tire_store_id"], :name => "index_tire_listings_on_tire_store_id"

  create_table "tire_manufacturers", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "tire_model_infos", :force => true do |t|
    t.integer  "tire_manufacturer_id"
    t.string   "tire_model_name"
    t.string   "photo1_url"
    t.string   "photo2_url"
    t.string   "photo3_url"
    t.string   "photo4_url"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
    t.string   "stock_photo1_file_name"
    t.string   "stock_photo1_content_type"
    t.integer  "stock_photo1_file_size"
    t.datetime "stock_photo1_updated_at"
    t.string   "stock_photo2_file_name"
    t.string   "stock_photo2_content_type"
    t.integer  "stock_photo2_file_size"
    t.datetime "stock_photo2_updated_at"
    t.string   "stock_photo3_file_name"
    t.string   "stock_photo3_content_type"
    t.integer  "stock_photo3_file_size"
    t.datetime "stock_photo3_updated_at"
    t.string   "stock_photo4_file_name"
    t.string   "stock_photo4_content_type"
    t.integer  "stock_photo4_file_size"
    t.datetime "stock_photo4_updated_at"
    t.text     "description"
  end

  create_table "tire_models", :force => true do |t|
    t.integer  "tire_manufacturer_id"
    t.integer  "tire_size_id"
    t.integer  "load_index"
    t.string   "speed_rating"
    t.float    "rim_width"
    t.float    "tread_depth"
    t.string   "utqg_temp"
    t.integer  "utqg_treadwear"
    t.string   "utqg_traction"
    t.string   "sidewall"
    t.datetime "created_at",                           :null => false
    t.datetime "updated_at",                           :null => false
    t.string   "name"
    t.integer  "orig_cost"
    t.integer  "tire_category_id",     :default => 0
    t.string   "product_code",         :default => ""
    t.string   "construction"
    t.float    "weight"
    t.integer  "warranty_miles"
    t.string   "tire_code"
    t.integer  "tire_model_info_id",   :default => -1
    t.string   "manu_part_num",        :default => ""
  end

  create_table "tire_searches", :force => true do |t|
    t.integer  "auto_manufacturer_id"
    t.integer  "auto_model_id"
    t.integer  "auto_year_id"
    t.integer  "auto_options_id"
    t.integer  "tire_size_id"
    t.integer  "user_id"
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.string   "locationstr"
    t.float    "latitude"
    t.float    "longitude"
    t.integer  "radius",                 :default => 20
    t.integer  "quantity",               :default => 0
    t.string   "saved_search_frequency"
    t.integer  "saved_search_dow"
    t.boolean  "send_text",              :default => false
    t.string   "text_phone"
    t.string   "new_or_used",            :default => "b"
  end

  create_table "tire_sizes", :force => true do |t|
    t.string   "sizestr"
    t.integer  "diameter"
    t.integer  "ratio"
    t.decimal  "wheeldiameter"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "tire_stores", :force => true do |t|
    t.string   "name"
    t.string   "address1"
    t.string   "address2"
    t.string   "city"
    t.string   "state"
    t.string   "zipcode"
    t.string   "phone"
    t.integer  "account_id"
    t.float    "latitude"
    t.datetime "created_at",                                                    :null => false
    t.datetime "updated_at",                                                    :null => false
    t.float    "longitude"
    t.string   "contact_email"
    t.boolean  "private_seller",                             :default => false
    t.boolean  "hide_phone",                                 :default => false
    t.boolean  "send_text",                                  :default => false
    t.string   "text_phone"
    t.string   "domain"
    t.hstore   "colors"
    t.hstore   "authorized_promotion_tire_manufacturer_ids"
    t.integer  "affiliate_id",                               :default => -1,    :null => false
    t.date     "affiliate_time"
    t.string   "affiliate_referrer"
  end

  add_index "tire_stores", ["authorized_promotion_tire_manufacturer_ids"], :name => "promotions_tire_manufacturer_ids"
  add_index "tire_stores", ["colors"], :name => "tire_stores_colors"
  add_index "tire_stores", ["domain"], :name => "index_tire_stores_on_domain"

  create_table "tire_stores_distributors", :force => true do |t|
    t.integer  "tire_store_id"
    t.integer  "distributor_id"
    t.hstore   "tire_manufacturers"
    t.integer  "frequency_days"
    t.datetime "next_run_time"
    t.datetime "last_run_time"
    t.integer  "records_created"
    t.integer  "records_updated"
    t.integer  "records_untouched"
    t.integer  "records_deleted"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
    t.string   "username"
    t.string   "password_digest"
  end

  add_index "tire_stores_distributors", ["distributor_id"], :name => "index_tire_stores_distributors_on_distributor_id"
  add_index "tire_stores_distributors", ["tire_store_id"], :name => "index_tire_stores_distributors_on_tire_store_id"

  create_table "tires", :force => true do |t|
    t.integer  "year"
    t.string   "sidewall"
    t.string   "speedrating"
    t.string   "performancecategory"
    t.integer  "tire_manufacturer_id"
    t.integer  "tire_size_id"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
  end

  create_table "users", :force => true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "email"
    t.string   "password_digest"
    t.string   "phone"
    t.integer  "status"
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.string   "remember_token"
    t.integer  "admin",                  :default => 0
    t.integer  "account_id",             :default => 0
    t.boolean  "tireseller",             :default => false
    t.string   "password_reset_token"
    t.datetime "password_reset_sent_at"
    t.string   "mobile_token"
    t.integer  "tire_store_id"
    t.integer  "affiliate_id",           :default => -1,    :null => false
    t.date     "affiliate_time"
    t.string   "affiliate_referrer"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["remember_token"], :name => "index_users_on_remember_token"

end
