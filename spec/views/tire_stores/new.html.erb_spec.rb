require 'spec_helper'

describe "tire_stores/new" do
  before(:each) do
    assign(:tire_store, stub_model(TireStore).as_new_record)
  end
end
