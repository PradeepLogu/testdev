require 'spec_helper'

describe "tires/index" do
  before(:each) do
    assign(:tires, [
      stub_model(Tire),
      stub_model(Tire)
    ])
  end
end
