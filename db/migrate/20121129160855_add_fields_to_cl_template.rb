class AddFieldsToClTemplate < ActiveRecord::Migration
  def change
    add_column :cl_templates, :cl_email, :string
    add_column :cl_templates, :cl_password, :string
    add_column :cl_templates, :cl_posting_page, :string
    add_column :cl_templates, :cl_subarea, :string
    add_column :cl_templates, :cl_specific_location, :string
    add_column :cl_templates, :cl_login_page, :string
    add_column :cl_templates, :cl_logout_page, :string
    add_column :cl_templates, :cl_login_email_fieldname, :string
    add_column :cl_templates, :cl_login_password_fieldname, :string
    add_column :cl_templates, :cl_ad_name, :string
    add_column :cl_templates, :cl_ad_value, :string
    add_column :cl_templates, :cl_category_name, :string
    add_column :cl_templates, :cl_category_value, :string
    add_column :cl_templates, :cl_title_field, :string
    add_column :cl_templates, :cl_price_field, :string
    add_column :cl_templates, :cl_specific_location_field, :string
    add_column :cl_templates, :cl_actions, :text
  end
end
