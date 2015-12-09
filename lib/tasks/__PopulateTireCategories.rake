require 'nokogiri'
#require 'rest_client'
require 'open-uri'

def ReadData(url)
    #RestClient.get url, :user_agent => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) "
    puts url
    open(url, "User-Agent" => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) ").read
end

namespace :PopulateTireCategories do
    desc "Scrape TireRack for tire categories for all tire models"
    task populate: :environment do
        @fail = 0
        @good = 0
        @all_categories = []
        @all_types = []
        brands = [
                    ["BFGoodrich", "http://www.tirerack.com/tires/bfg/bfgoodrich-tires.jsp"],
                    ["Bridgestone", "http://www.tirerack.com/tires/bridgestone/bridgestone-tires.jsp"],
                    ["Continental", "http://www.tirerack.com/tires/conti/continental-tires.jsp"],
                    #["Cooper"
                    #["Cordovan"
                    ["Dick Cepek", "http://www.tirerack.com/tires/dick-cepek/dick-cepek-tires.jsp"],
                    ["Dunlop", "http://www.tirerack.com/tires/dunlop/dunlop-tires.jsp"],
                    #["Falken"
                    #["Federal"
                    ["Firestone", "http://www.tirerack.com/tires/firestone/firestone-tires.jsp"],
                    ["Fuzion", "http://www.tirerack.com/tires/fuzion/fuzion-tires.jsp"],
                    #["GT Radial"
                    ["General", "http://www.tirerack.com/tires/general/general-tires.jsp"],
                    ["Goodyear", "http://www.tirerack.com/tires/goodyear/goodyear-tires.jsp"],
                    ["Hankook", "http://www.tirerack.com/tires/hankook/hankook-tires.jsp"],
                    ["Hoosier", "http://www.tirerack.com/tires/hoosier/hoosier-tires.jsp"],
                    #["Kelly"
                    ["Kumho", "http://www.tirerack.com/tires/kumho/kumho-tires.jsp"],
                    #["Mastercraft"
                    ["Michelin", "http://www.tirerack.com/tires/michelin/michelin-tires.jsp"],
                    #["MultiMile"
                    #["Nexen"
                    #["Nitto"
                    ["Pirelli", "http://www.tirerack.com/tires/pirelli/pirelli-tires.jsp"],
                    ["Power King", "http://www.tirerack.com/tires/power_king/power-king-tires.jsp"],
                    ["Sumitomo", "http://www.tirerack.com/tires/sumitomo/sumitomo-tires.jsp"],
                    #["Telstar"
                    ["Toyo", "http://www.tirerack.com/tires/toyo/toyo-tires.jsp"],
                    ["Uniroyal", "http://www.tirerack.com/tires/uniroyal/uniroyal-tires.jsp"],
                    #["Vanderbilt"
                    ["Yokohama", "http://www.tirerack.com/tires/yokohama/yokohama-tires.jsp"]
                ]
        brands.each do |brand, url|
          #puts "--------------------------------------------------"
          #puts brand + " " + url
          #puts "--------------------------------------------------"
#if brand == "Pirelli"

          @manu = TireManufacturer.find_by_name(brand)
          if @manu.nil?
            puts "****COULD NOT FIND " + brand
          end

          type_response = ReadData(url)
          html_tire_types = Nokogiri::HTML(type_response.to_s)

          tables = html_tire_types.xpath("//table").each do |table|
            # the way they have this laid out sucks.  We have to process every node
            # and find the ones we care about...
            process_children(table)
          end

          html_tire_types.xpath("//img[contains(@src, 'tires/headers')]/@altXXX").each do |type|
            tire_type = type.text.strip()
            puts "Type=" + tire_type

            if !all_types.include?(tire_type)
              all_types << tire_type
            end

            # now find the list of categories for this type
            type.parent.parent.parent.xpath("p").each do |category_or_model|
              if category_or_model.xpath('b').text.strip().to_s != ''
                puts "     Category=" + category_or_model.xpath('b').text.strip()
              elsif category_or_model.xpath("a[contains(@href, 'tireModel')]").text.strip().to_s != ''
                puts "          Model=" + category_or_model.xpath("a[contains(@href, 'tireModel')]").text.strip()
              end
            end
          end
        end
        puts "Fail = #{@fail} Good = #{@good}"

        puts ""
        puts ""
        @all_categories.each do |c|
          puts c
        end
    end
#end
end

def process_children(node)
  if node.xpath('img[contains(@src, "tires/headers")]/@alt').text.strip().to_s != ""
    @tire_type = node.xpath('img[contains(@src, "tires/headers")]/@alt').text.strip
  elsif node.xpath('b').text.strip().to_s != "" and node.parent.xpath('p').text.strip().to_s != ""
    #puts "     " + node.xpath('b').text.strip().to_s
    @category = node.xpath('b').text.strip().to_s
    #puts "Type=" + @tire_type
    if !@all_categories.include?(@category)
      @all_categories << @category
    end

    @tire_category = TireCategory.find_or_create_by_category_name(@category)
  elsif node.xpath("a[contains(@href, 'tireModel')]").text.strip().to_s != ""
    #puts "                 " + node.xpath("a[contains(@href, 'tireModel')]").text.strip().to_s
    @model = node.xpath("a[contains(@href, 'tireModel')]").text.strip().to_s

    # do we have a corresponding tire_model record?
    @tire_models = TireModel.find_all_by_tire_manufacturer_id_and_name(@manu.id, @model)
    if @tire_models.nil? || @tire_models.count == 0
      # we couldn't find an EXACT match.  Let's see if we can find anything
      # that matches all the individual words
      arWords = @model.delete('(').delete(')').split(' ')
      matches = 0
      @matchWord = ''
      found = false
      wordCount = arWords.count
      @manu.tire_models.each do |m|
        if !found
          matches = 0
          arWords.each do |w|
            if m.name.match(w)
              matches += 1
            end
          end

          # now let's see how well we did
          if matches == wordCount || matches == arWords.count || 
              ((matches == arWords.count - 1) && arWords.count >= 2)
            found = true
            @matchWord = m.name
          end
        end
      end

      if found
        @good += 1
        puts "I *think* I matched #{@matchWord} to #{@model} (#{wordCount})"
        # now update the category
        TireModel.find_all_by_tire_manufacturer_id_and_name(@manu.id, @matchWord).each do |tm|
          tm.tire_category_id = @tire_category.id
          tm.save
        end
      else
        @fail += 1
        puts "Could not find " + @manu.name + " " + @model
        #@manu.tire_models.each do |m|
        #  puts "          " + m.name
        #end
      end
    else
      @good += 1
      #puts "Success! " + @manu.name + " " + @model + " " + @tire_models.count.to_s

      # now update the category
      TireModel.find_all_by_tire_manufacturer_id_and_name(@manu.id, @model).each do |tm|
        tm.tire_category_id = @tire_category.id
        tm.save
      end
    end
  end

  node.children.each do |c|
    process_children(c)
  end
end

