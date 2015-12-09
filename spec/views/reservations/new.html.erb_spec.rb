require 'spec_helper'

describe "reservations/new" do
  before(:each) do
    assign(:reservation, stub_model(Reservation,
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
    ).as_new_record)
  end
end
