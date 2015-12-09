require 'spec_helper'

describe "auto_options/new" do
  before(:each) do
    assign(:auto_option, stub_model(AutoOption).as_new_record)
  end
end
