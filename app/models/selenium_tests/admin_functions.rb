module SeleniumTests
	class AdminFunctions < SeleniumPage
		def initialize(driver)
			@driver = driver
		end

		def delete_user_if_exists(email)
			h = SeleniumTests::HomePage.new(@driver)
			h.open_homepage
			h.login_admin(@driver)
			h.open_users_page

			element = @driver.find_element(:xpath, "//tr[contains(., '#{email}')]")
			if element
				e = element.find_elements(:link_text, "Destroy").first
				if e
					e.click
					@driver.switch_to.alert.accept
				end
			end

			h.open_homepage
			h.logout(@driver)
		end
	end
end