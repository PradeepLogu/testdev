require 'rubygems'
require 'selenium-webdriver'
require 'applescript'

def start_recording
	#AppleScript.say "This is a test"
	script = '	tell application "QuickTime Player"
				    set newScreenRecording to new screen recording
				    tell newScreenRecording
				        start
				    end tell
				end tell'
	begin
		AppleScript.execute(script)	
	rescue Exception => e 
	end
end

def stop_recording
	script = '	tell application "QuickTime Player"
					stop document "screen recording"
				    tell last item of documents
						export in ("/tmp/quicktimeFile.m4v") using settings preset "480p"				    
				        close
				    end tell				
				end tell'
	begin
		AppleScript.execute(script)	
	rescue Exception => e 
	end
end

def bring_safari_to_front
	script = '	tell application "Safari"
   					activate
   					--set index of window select (first window whose name contains "")  to 1
				end tell'
	begin
		AppleScript.execute(script)	
	rescue Exception => e 
	end
end

def show_search_for_stores(driver)
	home_page = SeleniumTests::HomePage.new(driver)
	search_store_page = SeleniumTests::SearchTireStoresPage.new(driver)

	home_page.open_homepage
	sleep(30.0)
	home_page.goto_search_for_stores

	search_store_page.highlight_app_notice
	search_store_page.show_store_search
end

def purchase_tires(driver)
	listing_details = SeleniumTests::TireListingDetailsPage.new(driver)
	listing_details.open_online_purchase_listing(driver)
	listing_details.initiate_purchase

	complete_order = SeleniumTests::CompleteOrderPage.new(driver)
	complete_order.complete_order

	create_appt = SeleniumTests::CreateAppointmentPage.new(driver)
	create_appt.create_appointment
end

def simple_search(driver)
	home_page = SeleniumTests::HomePage.new(driver)

	home_page.open_homepage
	sleep(20.0)
	##home_page.login_jobseeker(driver)
	home_page.scroll_to_how_treadhunter_works
	home_page.scroll_to_featured_box
	home_page.scroll_to_search_box

	home_page.set_location_on_homepage
	home_page.set_radius_on_homepage
	home_page.select_make_on_homepage('Hyundai') #'Honda')
	home_page.select_model_on_homepage('Sonata') #'Civic')
	home_page.select_year_on_homepage('2010') #'2007')
	home_page.select_options_on_homepage('SE') # 'GX 4 Dr.')
	home_page.click_find_my_tires_by_vehicle_on_homepage

	search_results = SeleniumTests::TireSearchResultsPage.new(driver)
	search_results.scroll_to_nth_search_result(5)
	#scroll_to_nth_search_result(driver, 0)
	#search_results.scroll_to_results_footer
	search_results.collapse_all
	search_results.scroll_to_last_expandable
	search_results.expand_all
	search_results.scroll_to_last_expandable
	search_results.scroll_to_results_footer

	search_results.scroll_to_top_of_results(5.0)
	search_results.filter_used_tires
	search_results.filter_manufacturer
	#search_results.click_first_search_result
	search_results.click_third_search_result

	listing_details = SeleniumTests::TireListingDetailsPage.new(driver)
	listing_details.scroll_to_top_of_listing(1.0)
	listing_details.highlight_listing_details
	listing_details.contact_seller
	listing_details.create_reservation

	home_page.logout(driver)
end

def register_as_jobposter(driver)
	# delete existing user and account if exists

	home_page = SeleniumTests::HomePage.new(driver)
	admin_functions = SeleniumTests::AdminFunctions.new(driver)	
	th_landing = SeleniumTests::THLandingPage.new(driver)
	th_unified = SeleniumTests::THUnifiedPage.new(driver)
	my_th_page = SeleniumTests::MyTreadHunterPage.new(driver)
	edit_store_page = SeleniumTests::EditTireStorePage.new(driver)
	my_store_page = SeleniumTests::MyTireStorePage.new(driver)
	new_listings_page = SeleniumTests::NewMultipleListingsPage.new(driver)
	add_promotions_page = SeleniumTests::AddPromotionPage.new(driver)
	listing_page = SeleniumTests::TireListingDetailsPage.new(driver)

	if true
		admin_functions.delete_user_if_exists(SeleniumTests::THLandingPage.public_seller_email)
		admin_functions.logout(driver)
		sleep(15) # give me some time to set the recorder up

		home_page.open_homepage
		home_page.scroll_to_how_treadhunter_works
		home_page.scroll_to_featured_box
		home_page.scroll_to_search_box
		home_page.sell_your_tires

		th_landing.click_store_selling_new_tires
		th_landing.enter_public_store_info

		th_unified.show_sections
	else
		home_page.open_homepage
		home_page.login_admin(driver)
	end

	if true
		home_page.goto_mytreadhunter

		my_th_page.edit_first_store

		edit_store_page.highlight_text_instead_of_email_option
		edit_store_page.highlight_tabs_option
		edit_store_page.upload_logo

		home_page.goto_mytreadhunter
		my_th_page.highlight_search_stats
		my_th_page.highlight_first_store
		my_th_page.goto_first_store

		my_store_page.select_create_multiple

		new_listings_page.create_listings

		add_promotions_page.add_promotion
	end

	my_th_page.goto_mytreadhunter
	my_th_page.goto_first_store
	my_store_page.scroll_to_top_of_results(1.0)
	my_store_page.highlight_and_click_first_promotion

	listing_page.scroll_to_top_of_listing(1.0)
	listing_page.highlight_and_click_rebate
	listing_page.logout(driver)
end

namespace :RunTest do
    desc "sample"

    task buy_tires: :environment do
    	@production = false
    	driver = Selenium::WebDriver.for :chrome
		driver.manage.window.resize_to(1100, 720)

		purchase_tires(driver)
    end

    task sample: :environment do
    	@production = false

    	#start_recording
    	#bring_safari_to_front

    	if false
			#File file = new File("/tmp/firebug-1.9.1.xpi")
			firefoxProfile = Selenium::WebDriver::Firefox::Profile.new
			firefoxProfile.add_extension("/tmp/firebug-1.9.1.xpi")
			##firefoxProfile.setPreference("extensions.firebug.currentVersion", "1.9.1")

			driver =Selenium::WebDriver.for :firefox, :profile => firefoxProfile
		elsif false
			driver = Selenium::WebDriver.for :safari
		elsif false
			driver = Selenium::WebDriver.for :chrome
		elsif true
			driver = Selenium::WebDriver.for :chrome
		elsif true
			chrome_profile = Selenium::WebDriver::Chrome::Profile.new
			chrome_profile.add_extension("/tmp/chrome_screencastify.crx")
			#puts "#{File.dirname(__FILE__) +'/chrome_screencastify.crx'}"
			#chrome_profile.add_extension(File.dirname(__FILE__) +"/chrome_screencastify.crx")

			driver = Selenium::WebDriver.for :chrome#, :profile => chrome_profile)
			driver.profile = chrome_profile
		end

		#driver.manage.window.resize_to(1024, 768)
		driver.manage.window.resize_to(1100, 720)

		if false
			register_as_jobposter(driver)
			home_page = SeleniumTests::HomePage.new(driver)
			home_page.show_midtown_tire(driver)
		end
		simple_search(driver)
		show_search_for_stores(driver)

		stop_recording

		#driver.quit
	end
end