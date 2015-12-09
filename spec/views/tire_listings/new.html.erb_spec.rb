require 'spec_helper'

describe "tire_listings/new" do
  before(:each) do
    assign(:tire_listing, stub_model(TireListing).as_new_record)
  end
end
