module SeleniumTests
	class THUnifiedPage < SeleniumPage
		def initialize(driver)
			@driver = driver
		end

		def show_sections
			scroll_to_footer(@driver)

			element = @driver.find_element(:link_text, "LIST NEW TIRES")
			highlight_element(@driver, element, true) if element.displayed?

			element = @driver.find_element(:link_text, "LIST BULK USED TIRES")
			highlight_element(@driver, element, true) if element.displayed?

			element = @driver.find_element(:link_text, "NOT TODAY")
			highlight_element(@driver, element, true) if element.displayed?

			#scroll_to_element(@driver, "div#registration-mid-part-left > p > a", 1000, 'easeOutQuad', 3.0, 200, 0)
			#scroll_to_element(@driver, "div#registration-mid-part-left > p > a", 1000, 'easeOutQuad', 3.0, 200, 1)
			#scroll_to_element(@driver, "div#registration-mid-part-left > p > a", 1000, 'easeOutQuad', 3.0, 200, 2)
		end
	end
end