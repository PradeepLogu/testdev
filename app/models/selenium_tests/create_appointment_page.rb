module SeleniumTests
	class CreateAppointmentPage < SeleniumPage
		def initialize(driver)
			@driver = driver
		end

		def create_appointment
			wait = Selenium::WebDriver::Wait.new(:timeout => 30) # seconds

			sleep(10.0)

			input = wait.until {
				element = @driver.find_element(:xpath, "//input[@value='Create Appointment']")
				element if element.displayed?
			}
			if input
				highlight_element(@driver, input, true) if input.displayed?
			end
			input.click
		end
	end
end