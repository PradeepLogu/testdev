require 'spec_helper'

describe "tire_listings/index" do
  before(:each) do
    assign(:tire_listings, [
      stub_model(TireListing),
      stub_model(TireListing)
    ])
  end
end
