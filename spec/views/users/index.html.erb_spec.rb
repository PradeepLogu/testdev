require 'spec_helper'

describe "users/index" do
  before(:each) do
    assign(:users, [
      stub_model(User,
        :first_name => "First Name",
        :last_name => "Last Name",
        :email => "Email",
        :password_digest => "Password Digest",
        :phone => "Phone",
        :status => 1
      ),
      stub_model(User,
        :first_name => "First Name",
        :last_name => "Last Name",
        :email => "Email",
        :password_digest => "Password Digest",
        :phone => "Phone",
        :status => 1
      )
    ])
  end
end
