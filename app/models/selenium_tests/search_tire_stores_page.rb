module SeleniumTests
	class SearchTireStoresPage < SeleniumPage
		def initialize(driver)
			@driver = driver
		end

		def highlight_app_notice
			wait = Selenium::WebDriver::Wait.new(:timeout => 10) # seconds
			input = wait.until {
				element = @driver.find_element(:xpath, "//div[@id='gritter-notice-wrapper']")
				element if element.displayed?
			}
			if input
				highlight_element(@driver, input, true) if input.displayed?
			end
			sleep(5.0)
			@driver.execute_script("$.gritter.removeAll();")
		end

		def show_store_search
			highlight_and_input(@driver, "location", "des moines, iowa")

			element = @driver.find_element(:name, "commit")
			highlight_element(@driver, element, true) if element.displayed?
			element.click
			@driver.execute_script("$.gritter.removeAll();")

			scroll_to_footer(@driver)
			scroll_to_element(@driver, "div.clear", 1000, 'easeOutQuad', 1.0, 0, 0)

			sleep(3.0)

			highlight_and_input(@driver, "location", "lawrenceville, ga")
			
			element = @driver.find_element(:name, "commit")
			highlight_element(@driver, element, true) if element.displayed?
			element.click
			@driver.execute_script("$.gritter.removeAll();")

			scroll_to_footer(@driver)
			scroll_to_element(@driver, "div.clear", 1000, 'easeOutQuad', 1.0, 0, 0)

			element = @driver.find_elements(:xpath, "//a[.='Learn More']").first
			highlight_element(@driver, element, true) if element.displayed?
			element.click
		end
	end
end