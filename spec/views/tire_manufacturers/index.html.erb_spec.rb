require 'spec_helper'

describe "tire_manufacturers/index" do
  before(:each) do
    assign(:tire_manufacturers, [
      stub_model(TireManufacturer),
      stub_model(TireManufacturer)
    ])
  end
end
