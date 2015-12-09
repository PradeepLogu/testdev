require 'spec_helper'

describe "auto_options/index" do
  before(:each) do
    assign(:auto_options, [
      stub_model(AutoOption),
      stub_model(AutoOption)
    ])
  end
end
