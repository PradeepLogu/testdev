require 'spec_helper'

describe "auto_models/new" do
  before(:each) do
    assign(:auto_model, stub_model(AutoModel).as_new_record)
  end
end
