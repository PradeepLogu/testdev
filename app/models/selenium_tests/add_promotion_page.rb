module SeleniumTests
	class AddPromotionPage < SeleniumPage
		def initialize(driver)
			@driver = driver
		end

		def add_promotion
			wait = Selenium::WebDriver::Wait.new(:timeout => 10) # seconds

			goto_mytreadhunter

			element = @driver.find_element(:link_text, "ADD PROMOTION")
			highlight_element(@driver, element, true) if element.displayed?
			element.click

			# highlight level (account/national)
			element = @driver.find_elements(:xpath, "//table/tbody/tr")[0]
			highlight_element(@driver, element, true) if element.displayed?

			# highlight type (rebate, %, etc.)
			element = @driver.find_elements(:xpath, "//table/tbody/tr")[1]
			highlight_element(@driver, element, true) if element.displayed?

			# highlight new/used
			element = @driver.find_elements(:xpath, "//table/tbody/tr")[2]
			highlight_element(@driver, element, true) if element.displayed?

			input = wait.until {
				element = Selenium::WebDriver::Support::Select.new(@driver.find_element(:id => "start_date_start_date_2i"))
			}
			input.select_by(:text, "January")

			input = wait.until {
				element = Selenium::WebDriver::Support::Select.new(@driver.find_element(:id => "start_date_start_date_3i"))
			}
			input.select_by(:text, "1")

			input = wait.until {
				element = Selenium::WebDriver::Support::Select.new(@driver.find_element(:id => "end_date_end_date_2i"))
			}
			input.select_by(:text, "December")

			input = wait.until {
				element = Selenium::WebDriver::Support::Select.new(@driver.find_element(:id => "end_date_end_date_3i"))
			}
			input.select_by(:text, "31")

			highlight_and_input(@driver, "promo_name", "TreadHunter Special!")
			highlight_and_input(@driver, "description", 
				"Buy four (4) new Michelin or Goodyear tires through TreadHunter.com from Joe's Tire Shack this year, " +
				"and you get a $100 Visa gift card!  To qualify for this offer, you much also purchase mounting and " +
				"balancing for the four tires.")

			
			#scroll_to_element(driver, css_selector, speed, easing, sleep, offset=0, index=0)
			input = wait.until {
				element = Selenium::WebDriver::Support::Select.new(@driver.find_elements(:id => "tire_manufacturer_").first)
			}
			input.select_by(:text, "Michelin")
			highlight_and_input(@driver, "tire_manufacturer__min_rebate_", "100", 0)
			sleep(2.0) # wait for models to load
			scroll_to_element(@driver, "div.tire-models", 1000, 'easeOutQuad', 1.0, 0, 0)			
			# check all the boxes
			e = @driver.find_elements(:xpath, "//div[@class='tire-models']").first
			e.find_elements(:xpath, "table/tbody/tr/td/input").each do |x|
				x.send_keys :space
			end

			element = @driver.find_element(:link_text, "ADD A NEW TIER")
			highlight_element(@driver, element, true) if element.displayed?
			element.click
			sleep(2.0)
			input = wait.until {
				element = Selenium::WebDriver::Support::Select.new(@driver.find_elements(:id => "tire_manufacturer_").second)
			}
			input.select_by(:text, "Goodyear")
			highlight_and_input(@driver, "tire_manufacturer__min_rebate_", "100", 1)
			sleep(2.0) # wait for models to load
			scroll_to_element(@driver, "div.tire-models", 1000, 'easeOutQuad', 1.0, 0, 1)
			# check all the boxes
			e = @driver.find_elements(:xpath, "//div[@class='tire-models']").second
			e.find_elements(:xpath, "table/tbody/tr/td/input").each do |x|
				x.send_keys :space
			end

			sleep(2.0) 
			scroll_to_element(@driver, "input.my-button", 1000, 'easeOutQuad', 1.0, 0, 0)
			element = @driver.find_element(:name, "commit")
			highlight_element(@driver, element, true) if element.displayed?
			element.click
		end
	end
end