module SeleniumTests
	class NewMultipleListingsPage < SeleniumPage
		def initialize(driver)
			@driver = driver
		end

		def create_listings
			wait = Selenium::WebDriver::Wait.new(:timeout => 10) # seconds

			element = @driver.find_element(:xpath, "//div[@id='inc_mounting']")
			highlight_element(@driver, element, true) if element.displayed?

			input = wait.until {
				element = Selenium::WebDriver::Support::Select.new(@driver.find_element(:name => "tire_manufacturer_id"))
			}
			input.select_by(:text, "Continental")

			sleep(2.0) # wait until models load
			input = wait.until {
				element = Selenium::WebDriver::Support::Select.new(@driver.find_element(:xpath => "//select[@id='tire_model']"))
			}
			input.select_by(:value, "ContiProContact")

			sleep(2.0) # wait until sizes load
			scroll_to_footer(@driver)
			scroll_to_element(@driver, "div#choose-tire-sizes", 1000, 'easeOutQuad', 1.0)
			scroll_to_element(@driver, "div#seller-mid-part", 1000, 'easeOutQuad', 1.0)

			element = @driver.find_element(:xpath, "//input[@id='tire_size_str']")
			highlight_element(@driver, element, false) if element.displayed?
			sleep(3.0)
			element.send_keys("2155517")
			
			sleep(2.0) # wait until sizes load
			scroll_to_footer(@driver)
			scroll_to_element(@driver, "div#choose-tire-sizes", 1000, 'easeOutQuad', 1.0)

			i = 0
			@numbers_to_add = [0, 3, 7, 9, 10, 12, 14, 17, 18, 21, 23, 25, 31, 34, 37]
			@driver.find_elements(:xpath, "//input[@id='tire_models_']").each do |e|
				if e.displayed?
					if @numbers_to_add.include?(i)
						highlight_element(@driver, e, false)
						e.click

						e2 = @driver.find_elements(:id, "price_#{e.attribute('value')}").first
						highlight_element(@driver, e2, false)
						e2.clear
						price = rand(190..260) + 0.95
						e2.send_keys price.to_s
					end 
					i += 1
					break if i > @numbers_to_add.last
				end
			end

			element = @driver.find_element(:xpath, "//input[@name='create_by_size']")
			highlight_element(@driver, element, true) if element.displayed?
			element.click
		end
	end
end
