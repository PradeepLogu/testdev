describe "the signup process", :type => :feature do
	before :each do
		if !User.find_by_email('user@example.com')
			u = User.new
			u.email = 'user@example.com'
			u.first_name = 'Bob'
			u.last_name = 'Jones'
			u.password = 'caplin'
			u.password_confirmation = 'caplin'
			u.phone = '7705551212'
			u.save
		end

		if !User.find_by_email('admin@example.com')
			u = User.new
			u.email = 'admin@example.com'
			u.first_name = 'Captain'
			u.last_name = 'America'
			u.password = 'iownthisplace'
			u.password_confirmation = 'iownthisplace'
			u.phone = '7705551212'
			u.admin = 1
			u.status = 2
			u.save
		end
	end

	it "fails to sign in with invalid account" do
		#visit '/signout'
		visit '/sessions/new'
		within(".row") do
			fill_in 'Email', :with => 'user@example.com'
			fill_in 'Password', :with => 'invalidpw'
		end
		click_button 'Sign in'
		page.should have_content 'Invalid email/password combination'
	end

	it "signs in buyer" do
		#visit '/signout'
		visit '/sessions/new'
		within(".row") do
			fill_in 'Email', :with => 'user@example.com'
			fill_in 'Password', :with => 'caplin'
		end
		click_button 'Sign in'
		page.should have_content 'Successful login'
		# homepage?
		page.should have_content 'TreadHunter strives'
	end

	it "signs in superuser" do
		#visit '/signout'
		visit '/sessions/new'
		within(".row") do
			fill_in 'Email', :with => 'admin@example.com'
			fill_in 'Password', :with => 'iownthisplace'
		end
		click_button 'Sign in'
		page.should have_content 'Select an Account'
	end
end