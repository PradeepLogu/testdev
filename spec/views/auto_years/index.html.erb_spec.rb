require 'spec_helper'

describe "auto_years/index" do
  before(:each) do
    assign(:auto_years, [
      stub_model(AutoYear),
      stub_model(AutoYear)
    ])
  end
end
