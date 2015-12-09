module SeleniumTests
	class MyTreadHunterPage < SeleniumPage
		def initialize(driver)
			@driver = driver
		end

		def goto_first_store
			e = @driver.find_elements(:xpath, "//div[@class='data-box' and @id='search-options']/p/a[contains(., 'View')]").first
			highlight_element(@driver, e, true)
			e.click
		end

		def highlight_first_store
			e = @driver.find_elements(:xpath, "//div[@class='data-box' and @id='search-options']/p").first
			highlight_element(@driver, e, true)
		end

		def edit_first_store
			e = @driver.find_elements(:xpath, "//div[@class='data-box' and @id='search-options']/p/a[contains(., 'Edit')]").first
			highlight_element(@driver, e, true)
			e.click
		end

		def highlight_search_stats
			e = @driver.find_elements(:xpath, "//div[@class='stats-box' and contains(., 'Searches in your area')]").first
			highlight_element(@driver, e, true)
		end
	end
end