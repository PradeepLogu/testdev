require 'spec_helper'

describe "auto_manufacturers/new" do
  before(:each) do
    assign(:auto_manufacturer, stub_model(AutoManufacturer).as_new_record)
  end
end
