module SeleniumTests
	class EditTireStorePage < SeleniumPage
		def initialize(driver)
			@driver = driver
		end

		def highlight_text_instead_of_email_option
			scroll_to_footer(@driver)
			wait = Selenium::WebDriver::Wait.new(:timeout => 10) # seconds
			input = wait.until {
				element = @driver.find_element(:xpath, "//label[@for='tire_store_send_text']")
				highlight_element(@driver, element, true)
			}
			sleep(3.0)
		end

		def highlight_tabs_option
			wait = Selenium::WebDriver::Wait.new(:timeout => 10) # seconds
			scroll_to_element(@driver, "div#edit-mid-part", 1000, 'easeOutQuad', 1.0)
			input = wait.until {
				element = @driver.find_element(:xpath, "//div[contains(@class,'divider')][2]")
				highlight_element(@driver, element, true)
				element if element.displayed?
			}
		end

		def upload_logo
			wait = Selenium::WebDriver::Wait.new(:timeout => 10) # seconds
			scroll_to_element(@driver, "div#edit-mid-part", 1000, 'easeOutQuad', 1.0)
			input = wait.until {
				element = @driver.find_element(:name, "branding[logo]")
				highlight_element(@driver, element, true)
				element if element.displayed?
			}
			
			input.send_keys('/Users/Kevin/Documents/joes_tire_shack_logo.jpg')
			sleep(3.0)

			scroll_to_footer(@driver)

			input = wait.until {
				element = @driver.find_element(:name, "commit")
				highlight_element(@driver, element, true)
				element if element.displayed?
			}
			
			sleep(3.0)
			input.click if input
		end
	end
end