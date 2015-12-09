FactoryGirl.define do
  factory :user do
  	first_name	 "Kevin"
    last_name    "Irick"
    email    	"michael@example.com"
    password 	"foobar"
    password_confirmation "foobar"
  end
end