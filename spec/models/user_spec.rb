require 'spec_helper'

describe User do

  before { @user = User.new(first_name: "Example", last_name: "User", email: "user@example.com", password: "foobar", password_confirmation: "foobar") }

  subject { @user }

  it { should respond_to(:first_name) }
  it { should respond_to(:last_name) }
end
