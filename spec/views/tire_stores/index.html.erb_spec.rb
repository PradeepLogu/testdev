require 'spec_helper'

describe "tire_stores/index" do
  before(:each) do
    assign(:tire_stores, [
      stub_model(TireStore),
      stub_model(TireStore)
    ])
  end
end
