module SeleniumTests
	class TireSearchResultsPage < SeleniumPage
		def initialize(driver)
			@driver = driver
		end

		def scroll_to_top_of_results(sleep)
			scroll_to_element(@driver, "div.search-main-left", 2000, 'easeOutQuad', sleep)
		end

		def scroll_to_results_footer
			scroll_to_footer(@driver)
		end

		def filter_used_tires
			filter_search_results("condition_false") #used tires
		end

		def filter_manufacturer
			if dev_mode(@driver)
				filter_search_results("tire_manufacturer_10") #Goodyear
			else
				filter_search_results("tire_manufacturer_3") #Bridgestone
			end
		end

		def filter_search_results(element_name)
			scroll_to_top_of_results(1.0)
			scroll_to_element(@driver, ".search-content-right-box div span ul li ##{element_name}", 1000, 'easeOutQuad', 3.0)
			wait = Selenium::WebDriver::Wait.new(:timeout => 3) # seconds
			begin
				input = wait.until {
					element = @driver.find_elements(:id, "#{element_name}").last
					element if element.displayed?
				}
				if input
					input_parent = input.find_element(:xpath, "..") if input.displayed?
					highlight_element(@driver, input_parent, true) if input.displayed?
					input.send_keys :space
				end
				scroll_to_top_of_results(3.0)
			rescue Exception => e
				puts "got an error in filter_search_results"
			end
		end

		def expand_all
			@driver.execute_script("ddaccordion.expandall('expandable');")
		end

		def collapse_all
			@driver.execute_script("ddaccordion.collapseall('expandable');");
		end

		def scroll_to_last_expandable
			scroll_to_element(@driver, "div.arrowlistmenu", 5000, 'easeOutQuad', 3.0, 0, 2)
			sleep(3.0)
		end

		def expand_last_summary
			begin
				input = wait.until {
					element = @driver.find_elements(:xpath, "//h2[contains(@class, 'menuheader')]").last
					highlight_element(@driver, element) if element.displayed?
					element if element.displayed?
				}
				if input
					input.click
				end
			rescue Exception => e
			end				
		end

		def scroll_to_nth_search_result(n)
			wait = Selenium::WebDriver::Wait.new(:timeout => 10) # seconds
			input = wait.until {
				element = @driver.find_element(:xpath, "//div[@class='search-content-left-inner']")
			}

			(0..n).each do |i|
				begin
					@driver.execute_script("document.getElementsByClassName('search-content-left-inner')[#{i}].scrollIntoView(true);")
				rescue Exception => e
					puts "Error trying to scroll - #{e.message} - not gonna worry about it"
				end			
				sleep(1.0/3.0)
			end
		end		

		def click_first_search_result
			wait = Selenium::WebDriver::Wait.new(:timeout => 10) # seconds
			if false
				input = wait.until {
					element = @driver.find_element(:xpath, "//div[@class='search-content-left-inner']")
				}
				begin
					@driver.execute_script("smoothScroll.animateScroll(null, 'div#tirelistings_list', {speed: 500, easing: 'easeOutQuad'});")
					sleep(5.0)
				rescue Exception => e
					puts "Error trying to scroll - #{e.message} - not gonna worry about it"
				end	
			else
				scroll_to_element(@driver, "div#tirelistings_list", 500, 'easeOutQuad', 5.0)
			end

			begin
				input = wait.until {
					element = @driver.find_elements(:xpath, "//a[@class='search-right-b-img']").first
					highlight_element(@driver, element) if element.displayed?
					element if element.displayed?
				}
				if input
					input.click
				end
			rescue Exception => e
			end	
		end			

		def click_third_search_result
			wait = Selenium::WebDriver::Wait.new(:timeout => 10) # seconds

			scroll_to_element(@driver, "div#tirelistings_list", 500, 'easeOutQuad', 5.0)

			begin
				input = wait.until {
					element = @driver.find_elements(:xpath, "//a[@class='search-right-b-img']")[2]
					highlight_element(@driver, element) if element.displayed?
					element if element.displayed?
				}
				if input
					input.click
				end
			rescue Exception => e
			end	
		end		
	end
end