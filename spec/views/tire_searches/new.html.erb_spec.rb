require 'spec_helper'

describe "tire_searches/new" do
  before(:each) do
    assign(:tire_search, stub_model(TireSearch).as_new_record)
  end
end
