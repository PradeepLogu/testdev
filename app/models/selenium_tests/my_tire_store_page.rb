module SeleniumTests
	class MyTireStorePage < SeleniumPage
		def initialize(driver)
			@driver = driver
		end

		def select_create_multiple
			element = @driver.find_element(:link_text, "CREATE LISTINGS")
			highlight_element(@driver, element, true) if element.displayed?
			@driver.mouse.move_to element 

			element = @driver.find_element(:link_text, "CREATE MULTIPLE NEW TIRE LISTINGS")
			highlight_element(@driver, element, true) if element.displayed?
			element.click
		end

		def scroll_to_top_of_results(sleep)
			scroll_to_element(@driver, "div#search-content-inner", 2000, 'easeOutQuad', sleep)
		end

		def highlight_and_click_first_promotion
			element = @driver.find_elements(:xpath, "//div[@class='search-content-left-inner' and contains(., 'Save even more')]").first
			highlight_element(@driver, element, true) if element.displayed?

			element2 = @driver.find_elements(:xpath, "//span[@class='promotions' and contains(., 'Save even more')]").first
			highlight_element(@driver, element2, true) if element.displayed?

			element.find_element(:link_text, "VIEW TIRE").click
		end
	end
end