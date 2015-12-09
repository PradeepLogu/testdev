require 'spec_helper'

describe "users/new" do
  before(:each) do
    assign(:user, stub_model(User,
      :first_name => "MyString",
      :last_name => "MyString",
      :email => "MyString",
      :password_digest => "MyString",
      :phone => "MyString",
      :status => 1
    ).as_new_record)
  end
end
