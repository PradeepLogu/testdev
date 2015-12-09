module SeleniumTests
	class HomePage < SeleniumPage
		def initialize(driver)
			@production = false
			@driver = driver
		end

		def scroll_to_search_box
			scroll_to_element(@driver, "div#header-inner-tab", 1000, 'easeOutQuad', 3.0)
		end

		def scroll_to_how_treadhunter_works
			scroll_to_element(@driver, "div.content-left", 1000, 'easeOutQuad', 3.0)
		end

		def scroll_to_featured_box
			scroll_to_element(@driver, "div#container-inner", 1000, 'easeOutQuad', 3.0)
		end

		def open_homepage
			if @production
				@driver.get "http://www.treadhunter.com"
			else
				@driver.get "http://localhost:3000?pp=disable"
			end
		end

		def open_users_page
			if @production
				@driver.get "http://www.treadhunter.com/users"
			else
				@driver.get "http://localhost:3000/users"
			end
		end

		def sell_your_tires
			scroll_to_top(@driver)
			e = @driver.find_element(:xpath, "//li[contains(., 'sell your tires')]")
			highlight_element(@driver, e, true)
			e.click if e
		end

		def set_location_on_homepage
			wait = Selenium::WebDriver::Wait.new(:timeout => 10) # seconds
			input = wait.until {
				element = @driver.find_element(:id, "tire_search_locationstr")
				highlight_element(@driver, element) if element.displayed?
				element if element.displayed?
			}
			sleep(1.0/1.0)
			input.clear if input
			input.send_keys("Lawrenceville, GA") if input
		end

		def set_radius_on_homepage
			wait = Selenium::WebDriver::Wait.new(:timeout => 10) # seconds
			e = @driver.find_element(:css, "div.form-box-1 > span.th-radius div.jqTransformSelectWrapper > div > a.jqTransformSelectOpen")
			highlight_element(@driver, e)
			e.click
			sleep(1.0/1.0)
			input = wait.until {
				element = @driver.find_element(:xpath, "//a[.='50 miles']")
				element if element.displayed?
			}
			input.click if input
		end

		def select_make_on_homepage(make)
			wait = Selenium::WebDriver::Wait.new(:timeout => 10) # seconds
			e = @driver.find_element(:css, "#auto_manufacturers > div.jqTransformSelectWrapper > div > a.jqTransformSelectOpen")
			highlight_element(@driver, e)
			e.click
			sleep(1.0/1.0)
			input = wait.until {
				element = @driver.find_element(:xpath, "//a[.='#{make}']")
				element if element.displayed?
			}
			input.click if input
			sleep(1.0)
		end

		def select_model_on_homepage(model_name)
			wait = Selenium::WebDriver::Wait.new(:timeout => 10) # seconds
			input = wait.until {
				element = @driver.find_element(:xpath, "//a[.='#{model_name}']")
			}
			e = @driver.find_element(:css, "#auto_models > div.jqTransformSelectWrapper > div > a.jqTransformSelectOpen")
			highlight_element(@driver, e)
			e.click
			sleep(1.0/1.0)
			input = wait.until {
				element = @driver.find_element(:xpath, "//a[.='#{model_name}']")
				element if element.displayed?
			}		
			input.click if input
			sleep(1.0)
		end

		def select_year_on_homepage(year)
			wait = Selenium::WebDriver::Wait.new(:timeout => 10) # seconds
			input = wait.until {
				element = @driver.find_element(:xpath, "//a[.='#{year}']")
			}	
			e = @driver.find_element(:css, "#auto_years > div.jqTransformSelectWrapper > div > a.jqTransformSelectOpen")
			highlight_element(@driver, e)
			e.click
			sleep(1.0/1.0)
			input = wait.until {
				element = @driver.find_element(:xpath, "//a[.='#{year}']")
				element if element.displayed?
			}		
			input.click if input
			sleep(1.0)
		end

		def select_options_on_homepage(options)
			wait = Selenium::WebDriver::Wait.new(:timeout => 10) # seconds
			input = wait.until {
				element = @driver.find_element(:xpath, "//a[.='#{options}']")
			}	
			e = @driver.find_element(:css, "#auto_options > div.jqTransformSelectWrapper > div > a.jqTransformSelectOpen")
			highlight_element(@driver, e)
			e.click
			sleep(1.0/1.0)
			input = wait.until {
				element = @driver.find_element(:xpath, "//a[.='#{options}']")
				element if element.displayed?
			}
			input.click if input
			sleep(1.0)
		end

		def click_find_my_tires_by_vehicle_on_homepage
			wait = Selenium::WebDriver::Wait.new(:timeout => 3) # seconds
			input = wait.until {
				element = @driver.find_element(:name, "auto_search")
				highlight_element(@driver, element) if element.displayed?
				element if element.displayed?
			}
			input.click if input	
		end		
	end
end