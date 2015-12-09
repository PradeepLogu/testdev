require 'spec_helper'

describe "auto_models/index" do
  before(:each) do
    assign(:auto_models, [
      stub_model(AutoModel),
      stub_model(AutoModel)
    ])
  end
end
