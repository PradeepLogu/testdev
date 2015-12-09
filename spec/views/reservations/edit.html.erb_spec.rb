require 'spec_helper'

describe "reservations/edit" do
  before(:each) do
    @reservation = assign(:reservation, stub_model(Reservation,
      :user_id => 1,
      :tire_listing_id => 1,
      :buyer_email => "MyString",
      :seller_email => "MyString",
      :name => "MyString",
      :address => "MyString",
      :city => "MyString",
      :state => "MyString",
      :zip => "MyString",
      :phone => "MyString"
    ))
  end
end
