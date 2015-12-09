require 'spec_helper'

describe "auto_manufacturers/index" do
  before(:each) do
    assign(:auto_manufacturers, [
      stub_model(AutoManufacturer),
      stub_model(AutoManufacturer)
    ])
  end
end
