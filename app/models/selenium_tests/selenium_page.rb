module SeleniumTests
	class SeleniumPage
		def highlight_element(driver, element, change_background=false)
			if change_background
				@bg = element.style('background')
			end

			(1..3).each do |i|
				if change_background
					driver.execute_script("hlt = function(c) { c.style.border='2px solid yellow'; c.style.background='yellow';}; return hlt(arguments[0]);", element)
				else
					driver.execute_script("hlt = function(c) { c.style.border='2px solid yellow'; }; return hlt(arguments[0]);", element)
				end
				sleep(1.0/10.0)
				if change_background
					driver.execute_script("hlt = function(c) { c.style.border=''; c.style.background='#{@bg}'}; return hlt(arguments[0]);", element)	
				else
					driver.execute_script("hlt = function(c) { c.style.border=''; }; return hlt(arguments[0]);", element)	
				end
				sleep(1.0/10.0)
			end
		end

		def captcha_url(driver)
			if dev_mode(driver)
				"http://localhost:3000/pages/xyzzy_abcdef"
			else
				"http://www.treadhunter.com/pages/xyzzy_abcdef"				
			end
		end

		def show_midtown_tire(driver)
			@driver.get "http://www.treadhunter.com/tire_stores/13700"
			#scroll_to_element(driver, "div#footer-inner", 15000, 'easeOutQuad', 2.0)
			scroll_to_element(driver, "div#footer-inner", 3000, 'easeOutQuad', 5.0)
			#driver.execute_script("window.scrollBy(0,1500)", "")
			scroll_to_element(driver, "div#search-content-inner", 3000, 'easeOutQuad', 5.0)
			#sleep(5.0)
			(3..7).each do |i|
				wait = Selenium::WebDriver::Wait.new(:timeout => 10) # seconds
				input = wait.until {
					element = driver.find_element(:xpath, "//a[@id='cont-#{i}']")
					highlight_element(driver, element, true)
					element
				}
				input.click
				sleep(3.0)
			end
		end

		def scroll_to_element(driver, css_selector, speed, easing, sleep, offset=0, index=0)
			wait = Selenium::WebDriver::Wait.new(:timeout => 10) # seconds
			input = wait.until {
				element = driver.find_elements(:css, "#{css_selector}")[index]
			}
			driver.execute_script("smoothScroll.animateScroll(null, '#{css_selector}', {offset: #{offset}, speed: #{speed}, easing: '#{easing}'});")
			sleep(sleep)
		end	

		def highlight_and_input(driver, selector, data, index=0, highlight=true)
			scroll_to_element(driver, "##{selector}", 1000, 'easeOutQuad', 0.5, 100)

			e = driver.find_elements(:id, selector)[index]
			highlight_element(driver, e, true) if highlight == true
			e.clear if e
			e.send_keys(data) if e
		end

		def input_without_highlighting(driver, selector, data, index=0)
			highlight_and_input(driver, selector, data, index, false)
		end

		def dev_mode(driver)
			return driver.current_url.include?("localhost")
		end

		def scroll_to_footer(driver)
			scroll_to_element(driver, "div#footer-inner", 5000, 'easeOutQuad', 5.0)
		end

		def scroll_to_top(driver)
			scroll_to_element(driver, "head", 1000, 'easeOutQuad', 1.0)
		end

		def goto_mytreadhunter
			e = @driver.find_element(:xpath, "//li[contains(., 'my treadhunter')]")
			highlight_element(@driver, e, true)
			e.click if e
		end

		def goto_search_for_stores
			e = @driver.find_element(:xpath, "//li[contains(., 'search by store')]")
			highlight_element(@driver, e, true)
			e.click if e
		end

		def logout(driver)
			scroll_to_top(driver)
			wait = Selenium::WebDriver::Wait.new(:timeout => 3) # seconds
			begin
				input = wait.until {
					element = driver.find_element(:link_text, "SIGN OUT")
					highlight_element(@driver, element, true) if element.displayed?
					element if element.displayed?
				}
				input.click if input
			rescue Exception => e 
			end
		end

		def login_jobseeker(driver)
			if dev_mode(driver)
				login(driver, "joe@tirebuyer.com", "foobar")
			else
				login(driver, "user@irick.net", "foobar")
			end
		end

		def login_jobposter(driver)
			if dev_mode(driver)
				login(driver, "rich.milne@midtowntires.com", "foobar")
			else
				login(driver, "jsjsjsjs@jsjsjs.com", "foobar")
			end
		end

		def login_admin(driver)
			login(driver, "kevin@irick.net", "foobar")
		end

		def login(driver, username, password)
			scroll_to_top(driver)
			logout(driver)
			wait = Selenium::WebDriver::Wait.new(:timeout => 10) # seconds
			input = wait.until {
				element = driver.find_element(:link_text, "SIGN IN")
				highlight_element(driver, element, true) if element.displayed?
				element if element.displayed?
			}
			if input
				input.click
				input = wait.until {
		    		element = driver.find_element(:id, "session_email")
		    		highlight_element(driver, element) if element.displayed?
		    		element if element.displayed?
				}
				input.clear
				input.send_keys(username)
				input = wait.until {
		    		element = driver.find_element(:id, "session_password")
		    		highlight_element(driver, element) if element.displayed?
		    		element if element.displayed?
				}
				input.clear
				input.send_keys(password)
				driver.find_element(:xpath, '//input[@value="Sign In"]').click
			else
				puts "*** didn't find signin"
			end
		end		
	end
end