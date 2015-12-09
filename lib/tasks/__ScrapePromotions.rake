require 'nokogiri'
require 'open-uri'

def ReadData(url)
    RestClient.get url, :user_agent => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) "
    #open(url, :proxy => "http://54.243.138.45:80", "User-Agent" => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) ").read
end

class BridgestoneRewardsScraper
  def Scrape
    getCookieURL = "http://www.bridgestonerewards.com/find-a-claim-form.aspx"
    response = RestClient.get getCookieURL
    puts response.cookies
    puts response.headers
    
    url = "http://www.bridgestonerewards.com/services/proxy.aspx?path=offers&authorizationToken=ae6a337d-f214-46cf-821b-3a338b1c9314&categoryId=ade44591-445f-4cb4-8c7b-f67836453f6a&purchasedate=2013-12-11"

    bridgestone_json = ''
    (1..5).each do |i|
        begin
            bridgestone_json = ReadData(url)
            break
        rescue Exception => e 
            puts "Error processing #{url}: #{e.to_s} - try again"
        end
    end
    if bridgestone_json != '' # there was no error
      h = JSON.parse(bridgestone_json)
      h.each do |r|
        puts "#{r['offerId']}"
        offerId = r["offerId"]
        offerNumber = r["offerNumber"]
        offerTitle = r["offerTitle"]
        offerStart = r["offerStartDate"]
        offerEnd = r["offerEndDate"]
        offerDisclaimer = r["offerDisclaimer"]
        offerAddlInfo = r["additionalInformation"]
        offerRebateURL = r["rebateFormUrl"]
        
      end
    end
  end
end

namespace :ScrapePromotions do
    desc "Create promotions data"
    task populate: :environment do
      b = BridgestoneRewardsScraper.new
      b.Scrape()
    end
end