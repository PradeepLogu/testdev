require 'spec_helper'

describe "users/show" do
  before(:each) do
    @user = assign(:user, stub_model(User,
      :first_name => "First Name",
      :last_name => "Last Name",
      :email => "Email",
      :password_digest => "Password Digest",
      :phone => "Phone",
      :status => 1
    ))
  end
end
