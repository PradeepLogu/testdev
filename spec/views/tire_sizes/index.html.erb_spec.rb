require 'spec_helper'

describe "tire_sizes/index" do
  before(:each) do
    assign(:tire_sizes, [
      stub_model(TireSize),
      stub_model(TireSize)
    ])
  end
end
