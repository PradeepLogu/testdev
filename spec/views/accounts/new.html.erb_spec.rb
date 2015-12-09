require 'spec_helper'

describe "accounts/new" do
  before(:each) do
    assign(:account, stub_model(Account).as_new_record)
  end
end
