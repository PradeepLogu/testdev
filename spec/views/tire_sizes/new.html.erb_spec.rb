require 'spec_helper'

describe "tire_sizes/new" do
  before(:each) do
    assign(:tire_size, stub_model(TireSize).as_new_record)
  end
end
