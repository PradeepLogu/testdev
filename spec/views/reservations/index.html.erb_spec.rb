require 'spec_helper'

describe "reservations/index" do
  before(:each) do
    assign(:reservations, [
      stub_model(Reservation,
        :user_id => 1,
        :tire_listing_id => 2,
        :buyer_email => "Buyer Email",
        :seller_email => "Seller Email",
        :name => "Name",
        :address => "Address",
        :city => "City",
        :state => "State",
        :zip => "Zip",
        :phone => "Phone"
      ),
      stub_model(Reservation,
        :user_id => 1,
        :tire_listing_id => 2,
        :buyer_email => "Buyer Email",
        :seller_email => "Seller Email",
        :name => "Name",
        :address => "Address",
        :city => "City",
        :state => "State",
        :zip => "Zip",
        :phone => "Phone"
      )
    ])
  end
end
