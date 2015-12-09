require 'spec_helper'

describe "tires/new" do
  before(:each) do
    assign(:tire, stub_model(Tire).as_new_record)
  end
end
