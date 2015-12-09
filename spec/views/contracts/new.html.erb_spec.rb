require 'spec_helper'

describe "contracts/new" do
  before(:each) do
    assign(:contract, stub_model(Contract,
      :account_id => 1,
      :contract_amount => 1,
      :can_post_listings => false,
      :can_use_mobile => false,
      :can_use_logo => false,
      :can_use_branding => false,
      :can_have_search_portal => false,
      :can_have_filter_portal => false,
      :max_monthly_listings => 1
    ).as_new_record)
  end
end
