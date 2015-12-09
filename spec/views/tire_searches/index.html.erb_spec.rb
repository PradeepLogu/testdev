require 'spec_helper'

describe "tire_searches/index" do
  before(:each) do
    assign(:tire_searches, [
      stub_model(TireSearch),
      stub_model(TireSearch)
    ])
  end
end
