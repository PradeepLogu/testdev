module SeleniumTests
	class THLandingPage < SeleniumPage
		def initialize(driver)
			@driver = driver
		end

		def self.public_seller_email
			"joe@joestireshack.com"
		end

		def click_store_selling_new_tires
			e = @driver.find_elements(:xpath, "//button[@name='new']").first
			highlight_element(@driver, e, true) if e
			e.click if e
		end

		def click_store_selling_used_tires
			e = @driver.find_elements(:xpath, "//button[@name='used']").first
			highlight_element(@driver, e, true) if e
			e.click if e
		end

		def click_private_seller
			e = @driver.find_elements(:xpath, "//button[@name='private']").first
			highlight_element(@driver, e, true) if e
			e.click if e
		end

		def highlight_search_stats
			e = @driver.find_elements(:xpath, "//div[@class='stats-box' and contains(., 'Searches in your area')]").first
			highlight_element(@driver, e, true)
		end

		def highlight_and_input2(selector, data)
			highlight_and_input(@driver, selector, data)
		end

		def input_without_highlighting2(selector, data)
			input_without_highlighting(@driver, selector, data)
		end

		def input_first_name
			highlight_and_input2("registration_first_name", "Joe")
		end

		def input_last_name
			input_without_highlighting2("registration_last_name", "Tireseller")
		end

		def input_email
			highlight_and_input2("registration_email", THLandingPage.public_seller_email)
		end

		def input_phone
			highlight_and_input2("registration_phone", "770-555-1212")
		end

		def input_password
			input_without_highlighting2("registration_password", "foobar")
			input_without_highlighting2("registration_password_confirmation", "foobar")
		end

		def input_store_name
			highlight_and_input2("registration_name", "Joe's Tire Shack")
		end

		def input_store_address
			input_without_highlighting2("registration_address1", "4985 East Main Street")
			input_without_highlighting2("registration_city", "Atlanta")
			select_store_state("Georgia")
			input_without_highlighting2("registration_zipcode", "30331")
		end

		def click_sign_up
			e = @driver.find_elements(:xpath, "//input[@value='Sign up']").first
			highlight_element(@driver, e, true) if e
			e.click if e
		end

		def select_store_state(state)
			wait = Selenium::WebDriver::Wait.new(:timeout => 10) # seconds
			e = @driver.find_element(:css, "#state > div.jqTransformSelectWrapper > div > a.jqTransformSelectOpen")
			highlight_element(@driver, e)
			e.click
			sleep(1.0/1.0)
			input = wait.until {
				element = @driver.find_element(:xpath, "//a[.='#{state}']")
				element if element.displayed?
			}
			input.click if input
			sleep(1.0)
		end

		def enter_public_store_info
			input_first_name
			input_last_name
			input_email
			input_phone
			input_password
			input_store_name
			input_store_address
			click_sign_up
		end
	end
end