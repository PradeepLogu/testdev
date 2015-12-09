require 'spec_helper'

describe "auto_years/new" do
  before(:each) do
    assign(:auto_year, stub_model(AutoYear).as_new_record)
  end
end
