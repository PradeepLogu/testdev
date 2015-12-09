require 'nokogiri'
require 'rest_client'
require 'open-uri'

def RandomUserAgent
	@agents ||= [
					"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/36.0.1944.0 Safari/537.36",
					"Mozilla/5.0 (Windows NT 6.2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/28.0.1464.0 Safari/537.36",
					"Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.13 (KHTML, like Gecko) Chrome/24.0.1284.0 Safari/537.13",
					"Mozilla/5.0 (Windows NT 5.1; rv:31.0) Gecko/20100101 Firefox/31.0",
					"Mozilla/5.0 (Windows NT 6.2; Win64; x64; rv:21.0.0) Gecko/20121011 Firefox/21.0.0",
					"Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.1; WOW64; Trident/6.0)",
					"Mozilla/4.0(compatible; MSIE 7.0b; Windows NT 6.0)",
					"Mozilla/5.0 (Windows; U; Windows NT 6.1; rv:2.2) Gecko/20110201",
					"Opera/9.80 (Windows NT 6.0) Presto/2.12.388 Version/12.14",
					"Opera/9.80 (Windows NT 6.1; Opera Tablet/15165; U; en) Presto/2.8.149 Version/11.1",
					"Mozilla/5.0 (BlackBerry; U; BlackBerry 9900; en) AppleWebKit/534.11+ (KHTML, like Gecko) Version/7.1.0.346 Mobile Safari/534.11+"
				]
	return @agents[Random.rand(@agents.size) - 1]
end

def GetEndRecFromPage(sHTML, engine)
	s = Nokogiri::HTML(sHTML.to_s)
	if engine.downcase == "bing"
		page_str = s.xpath('//span[@class="sb_count"]').text()
		ar = page_str.scan(/.*\-(\d{1,}) .*/)[0]

		if ar.is_a?(String)
			return ar.to_i
		elsif ar.nil?
			return 14
		else
			#puts "#{ar.class.to_s}"
			return ar.first.to_i
		end
	elsif engine.downcase == "yahoo"
		next_str = s.xpath('//a[@id="pg-next"]').attribute("href").text()
		ar = next_str.scan(/.*pstart=(\d{1,}).*/)[0]
		if ar.is_a?(String)
			return ar.to_i - 1
		elsif ar.nil?
			return 8
		else
			return ar.first.to_i - 1
		end
	elsif engine.downcase == "google"
		page_str = s.xpath('//div[@id="resultStats"]').text()
		#puts "google - #{page_str}"
		#puts sHTML
		ar = page_str.scan(/Page (\d{1,}) of*/)[0]
		if ar.is_a?(String)
			return (ar.to_i * 10 - 1)
		elsif ar.nil?
			return 9
		else
			return (ar.first.to_i * 10 - 1)
		end
	end
end

def YahooURL(query, start_rec)
	q = URI::encode(query)
	"https://search.yahoo.com/search?p=#{q}&pstart=#{start_rec}"
end

def BingURL(query, start_rec)
	q = URI::encode(query)
	"http://www.bing.com/search?q=#{q}&go=&qs=n&form=QBLH&pq=#{q}&sc=2-20&first=#{start_rec}"
end

def GoogleURL(query, start_rec)
	q = URI::encode(query)
	"http://www.google.com/search?q=#{q}&oq=#{q}&start=#{start_rec}"
end

def ReadData(url)
	RestClient.get url, :user_agent => RandomUserAgent
    #RestClient.get url#, :user_agent => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) "
    #open(url, :proxy => "http://54.243.138.45:80", "User-Agent" => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) ").read
    #open(url, :proxy => "http://54.243.138.45:80", "User-Agent" => RandomUserAgent).read
end

def SleepRandomTime
	sleep_time = 15 + Random.rand(45)
	sleep(sleep_time)
end

def HitSearchEngine(url)
	sResult = ""
    (1..5).each do |j|
        begin
            sResult = ReadData(url)
            break
        rescue Exception => e
            puts "Error: #{e.to_s} - try again"
            puts url
            SleepRandomTime()
        end
    end
    return sResult
end

def GetURLForEngine(engine, querystring, start_rec)
	sURL = ""
	if engine.downcase == "google"
		sURL = GoogleURL(querystring, start_rec)
	elsif engine.downcase == "bing"
		sURL = BingURL(querystring, start_rec)
	elsif engine.downcase == "yahoo"
		sURL = YahooURL(querystring, start_rec)
	end
	return sURL
end

def Queries
	["Tires", 
    		"Used Tires", "Used Tires Lawrenceville GA", "Used Tires Atlanta GA",
    		"New Tires", "New Tires Lawrenceville GA", "New Tires Atlanta GA",
    		"Tire Stores Near Atlanta", "Cheap Tires Atlanta GA",
    		"Discount Tires Atlanta GA"]
	#["Used Tires Lawrenceville GA", "Used Tires Atlanta GA"]
end

namespace :SEOReport do
    desc "Run SEO Report"
    task run: :environment do
    	if Time.now.wday == 3
	    	search_engines = ["Google", "Bing"]#, "Yahoo"]
	    	#search_engines = ["Bing"]#, "Yahoo"]

	    	message_html = "<h1>SEO Report - #{Time.now.strftime('%m/%d/%Y')}</h1><br /><br />"

	    	message_html += "<table>"
	    	message_html += "<tr><th>Query</th>"
	    	search_engines.each do |engine|
	    		message_html += "<th>#{engine}</th>"
	    	end
	    	message_html += "</tr>"

	    	Queries().each do |q|
	    		start_rec = [0, 0, 0]
	    		row_message = ["Not Found", "Not Found", "Not Found"]
	    		(1..15).each do |i|
	    			index = 0
	    			search_engines.each do |engine|
	    				if start_rec[index] != -1
	    					SleepRandomTime() if index == 0

		    				url = GetURLForEngine(engine, q, start_rec[index])

			    			sHTML = HitSearchEngine(url)

			    			if sHTML.downcase.include?("treadhunter") || sHTML.downcase.include?("tread-hunter")
			    				puts "#{engine}: #{q} - page #{i} - #{url}"
			    				row_message[index] = "<a href='#{url}'>Page #{i} (~#{start_rec[index]})</a>"
			    				start_rec[index] = -1
			    			elsif sHTML.size == 0
			    				puts "Could not read...giving up"
			    			else
			    				puts "Not found on #{engine} - #{q} - page #{i} (#{start_rec[index]})"
			    			end

			    			if start_rec[index] != -1
			    				start_rec[index] = GetEndRecFromPage(sHTML, engine) + 1
			    			end
			    			#puts "Start_rec for #{engine} is now #{start_rec[index]}"
			    		end
		    			index += 1
	    			end
	    		end

	    		message_html += "<tr>"
	    		message_html += "<td>#{q}</td>"
	    		(0..search_engines.size - 1).each do |i|
	    			message_html += "<td>#{row_message[i]}</td>"
	    		end
	    		message_html += "</tr>"
	    	end
			message_html += "</table>"

			c = ContactUs.new()
			c.email = "treadhunter.mailer@gmail.com"
			c.sender_name = "SEO Report"
			c.support_type = "SEOREPORT"
			c.content = message_html
			ContactusMailer.generic_email(c, "gspence@treadhunter.com,aphelps@treadhunter.com,jbarker@treadhunter.com,kirick@treadhunter.com,prmikhail@aol.com", "SEO Report").deliver
		end
    end
end