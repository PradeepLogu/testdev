require 'spec_helper'

describe "accounts/index" do
  before(:each) do
    assign(:accounts, [
      stub_model(Account),
      stub_model(Account)
    ])
  end
end
