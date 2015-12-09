require 'spec_helper'

describe "tire_manufacturers/new" do
  before(:each) do
    assign(:tire_manufacturer, stub_model(TireManufacturer).as_new_record)
  end
end
