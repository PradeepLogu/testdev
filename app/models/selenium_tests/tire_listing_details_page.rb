module SeleniumTests
	class TireListingDetailsPage < SeleniumPage
		def initialize(driver)
			@driver = driver
		end

		def scroll_to_top_of_listing(sleep)
			scroll_to_element(@driver, "div#search-main2", 500, 'easeOutQuad', sleep)
		end

		def valid_listing_url(driver)
			if dev_mode(driver) || true
				"http://localhost:3000/tire_listings/2169910"
			else
				"http://www.google.com"				
			end
		end

		def open_online_purchase_listing(driver)
			@driver.get valid_listing_url(driver)
		end

		def initiate_purchase
			wait = Selenium::WebDriver::Wait.new(:timeout => 10) # seconds
			input = wait.until {
				element = @driver.find_element(:xpath, "//a[contains(., 'tires!')]")
				element if element.displayed?
			}
			if input
				highlight_element(@driver, input, true) if input.displayed?
			end
			input.click

			wait = Selenium::WebDriver::Wait.new(:timeout => 10) # seconds
			input = wait.until {
				element = @driver.find_element(:xpath, "//button[contains(., 'Buy Now!')]")
				element if element.displayed?
			}
			if input
				highlight_element(@driver, input, true) if input.displayed?
			end
			input.click
		end

		def contact_seller
			wait = Selenium::WebDriver::Wait.new(:timeout => 10) # seconds
			input = wait.until {
				element = @driver.find_element(:xpath, "//a[contains(., 'Contact Seller')]")
				element if element.displayed?
			}
			if input
				highlight_element(@driver, input, true) if input.displayed?
			end
			input.click

			# gotta get the captcha value through the back door
			captcha_value = JSON.parse(RestClient.get(captcha_url(@driver)))["captcha"]
			highlight_and_input(@driver, "contact_seller_email", "suzypublic@gmail.com", 0)
			highlight_and_input(@driver, "contact_seller_sender_name", "Suzy Q. Public", 0)
			highlight_and_input(@driver, "contact_seller_phone", "770-555-3838", 0)
			highlight_and_input(@driver, "contact_seller_content", "Hello, I am interested in letting you help me find tires for my Sonata.  Can you call me or email me at your convenience?", 0)
			highlight_and_input(@driver, "captcha", captcha_value, 1)
			input = wait.until {
				element = @driver.find_element(:xpath, "//input[@value='Send Message']")
				element if element.displayed?
			}
			if input
				highlight_element(@driver, input, true) if input.displayed?
			end
			input.click			
		end

		def create_reservation
			wait = Selenium::WebDriver::Wait.new(:timeout => 10) # seconds
			input = wait.until {
				element = @driver.find_element(:xpath, "//a[contains(., 'for me!')]")
				element if element.displayed?
			}
			if input
				highlight_element(@driver, input, true) if input.displayed?
			end
			input.click

			# gotta get the captcha value through the back door
			captcha_value = JSON.parse(RestClient.get(captcha_url(@driver)))["captcha"]
			highlight_and_input(@driver, "reservation_buyer_email", "suzypublic@gmail.com", 0)
			highlight_and_input(@driver, "reservation_name", "Suzy Q. Public", 0)
			highlight_and_input(@driver, "reservation_phone", "770-555-3838", 0)
			highlight_and_input(@driver, "captcha", captcha_value, 0)
			input = wait.until {
				element = @driver.find_element(:xpath, "//input[@value='Create Reservation']")
				element if element.displayed?
			}
			if input
				highlight_element(@driver, input, true) if input.displayed?
			end
			input.click			
		end

		def highlight_listing_details
			wait = Selenium::WebDriver::Wait.new(:timeout => 10) # seconds
			["//li[contains(., 'Category')]", "//li[contains(., 'Size')]", "//li[contains(., 'Willing')]"].each do |x|
				input = wait.until {
					element = @driver.find_elements(:xpath, x).last
					element if element.displayed?
				}
				if input
					highlight_element(@driver, input, true) if input.displayed?
				end
			end
		end

		def highlight_and_click_rebate
			wait = Selenium::WebDriver::Wait.new(:timeout => 10) # seconds
			begin
				input = wait.until {
					element = @driver.find_elements(:xpath, "//a[contains(., 'Save even more')]").last
					element if element.displayed?
				}
				if input
					highlight_element(@driver, input, true) if input.displayed?
					input.click
					sleep(5.0)
					element = @driver.find_element(:css, "a.ui-dialog-titlebar-close")
					element.click
				end
			rescue Exception => e
				puts "#{e.to_s} - in highlight_and_click_rebate"
			end
		end
	end
end