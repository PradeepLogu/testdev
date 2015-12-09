module SeleniumTests
	class CompleteOrderPage < SeleniumPage
		def initialize(driver)
			@driver = driver
		end

		def complete_order
			wait = Selenium::WebDriver::Wait.new(:timeout => 30) # seconds

			sleep(10.0)

			element = @driver.find_element(:xpath, "//input[@id='cardName']")
			highlight_element(@driver, element, false) if element.displayed?
			sleep(3.0)
			element.send_keys('Bobby Buyer')

			element = @driver.find_element(:xpath, "//input[@id='buyer_email']")
			highlight_element(@driver, element, false) if element.displayed?
			sleep(3.0)
			element.send_keys('bobby@irick.net')

			input = wait.until {
				element = @driver.find_element(:xpath, "//input[@id='buyer_phone']")
				element if element.displayed?
			}
			input.send_keys('7705551212')

			input = wait.until {
				element = @driver.find_element(:xpath, "//input[@id='cardAddress']")
				element if element.displayed?
			}
			input.send_keys('111 Main Street')

			input = wait.until {
				element = @driver.find_element(:xpath, "//input[@id='cardCity']")
				element if element.displayed?
			}
			input.send_keys('Atlanta')

			input = wait.until {
				element = @driver.find_element(:xpath, "//input[@id='cardZip']")
				element if element.displayed?
			}
			input.send_keys('30092')

			input = wait.until {
				element = @driver.find_element(:xpath, "//input[@id='cardNumber']")
				element if element.displayed?
			}
			input.send_keys('4242424242424242')

			input = wait.until {
				element = @driver.find_element(:xpath, "//input[@id='cardCVC']")
				element if element.displayed?
			}
			input.send_keys('456')

			input = wait.until {
				element = Selenium::WebDriver::Support::Select.new(@driver.find_element(:id => "cardState"))
			}
			input.select_by(:text, "Georgia")

			input = wait.until {
				element = Selenium::WebDriver::Support::Select.new(@driver.find_element(:id => "cardExpMonth"))
			}
			input.select_by(:text, "March")

			input = wait.until {
				element = Selenium::WebDriver::Support::Select.new(@driver.find_element(:id => "cardExpYear"))
			}
			input.select_by(:text, "2018")

			input = wait.until {
				element = @driver.find_element(:xpath, "//input[@value='Submit Payment']")
				element if element.displayed?
			}
			if input
				highlight_element(@driver, input, true) if input.displayed?
			end
			input.click
		end
	end
end