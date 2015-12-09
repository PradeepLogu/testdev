require 'nokogiri'
require 'open-uri'
require 'thread/pool'

def ReadJSONData(url)
  result = nil
  (1..5).each do |i|
    begin
      result = JSON.load(open(url))
    rescue Interrupt => e
      result = "INTERRUPT"
    rescue Exception => e 
      puts "Error reading #{url} (#{e.to_s}) - attempt #{i}"
      result = nil
    end
  end
  if result.blank?
    result = nil
  end
  ## puts "Just read #{url}"
  return result
end

def TranslateManuName(name)
  if name == "Mercedes-Benz"
    return "Mercedes Benz"
  else
    return name 
  end
end

def replace_tire_search_vehicles(start_time)
    replace_log = []
    confidence = FuzzyStringMatch::JaroWinkler.create(:pure)
    TireSearch.find(:all, :conditions => ['auto_options_id > 0']).each do |t|
      begin
        old_auto_option_record = AutoOption.find(t.auto_options_id)

        if old_auto_option_record.updated_at < start_time
          old_auto_year_record = AutoYear.find(t.auto_year_id)
          old_auto_model_record = AutoModel.find(t.auto_model_id)
          old_auto_manu_record = AutoManufacturer.find(t.auto_manufacturer_id)

          matcher = FuzzyMatch.new(AutoOption.find(:all, :conditions => ["auto_year_id = ? and updated_at > ?", t.auto_year_id, start_time]), :read => :name)
          best_guess = matcher.find(old_auto_option_record.name)
          if best_guess
            # check confidence score
            con = confidence.getDistance(best_guess.name.downcase, old_auto_option_record.name.downcase)
            replace_log << "Search record: #{t.id} Con: #{con} Replacing #{old_auto_option_record.auto_year.modelyear} #{old_auto_option_record.auto_manufacturer.name} #{old_auto_option_record.auto_model.name} #{old_auto_option_record.name}"
            replace_log << "                                        with #{best_guess.auto_year.modelyear} #{best_guess.auto_manufacturer.name} #{best_guess.auto_model.name} #{best_guess.name}"
            replace_log << " "
            t.update_column(:auto_year_id, best_guess.auto_year.id)
            t.update_column(:auto_model_id, best_guess.auto_model.id)
            t.update_column(:auto_manufacturer_id, best_guess.auto_manufacturer.id)
            t.update_column(:auto_options_id, best_guess.id)
          else
            replace_log << "Search record: #{t.id} Could not find suitable replacement for #{old_auto_option_record.auto_year.modelyear} #{old_auto_option_record.auto_manufacturer.name} #{old_auto_option_record.auto_model.name} #{old_auto_option_record.name} - deleting vehicle"
            replace_log << " "
            t.update_column(:auto_year_id, nil)
            t.update_column(:auto_model_id, nil)
            t.update_column(:auto_manufacturer_id, nil)
            t.update_column(:auto_options_id, nil)
          end
        end
      rescue Exception => e 
        replace_log <<"Exception trying to update old search #{e.to_s} - Search ID: #{t.id}"
        puts "Exception trying to update old search #{e.to_s}"
      end
    end
    return replace_log
end

def replace_appointment_vehicles(start_time)
    replace_log = []
    confidence = FuzzyStringMatch::JaroWinkler.create(:pure)
    Appointment.find(:all, :conditions => ['auto_option_id > 0']).each do |appt|
      begin
        old_auto_option_record = AutoOption.find(appt.auto_option_id)

        if old_auto_option_record.updated_at < start_time
          old_auto_year_record = AutoYear.find(appt.auto_year_id)
          old_auto_model_record = AutoModel.find(appt.auto_model_id)
          old_auto_manu_record = AutoManufacturer.find(appt.auto_manufacturer_id)

          matcher = FuzzyMatch.new(AutoOption.find(:all, :conditions => ["auto_year_id = ? and updated_at > ?", appt.auto_year_id, start_time]), :read => :name)
          best_guess = matcher.find(old_auto_option_record.name)
          if best_guess
            # check confidence score
            con = confidence.getDistance(best_guess.name.downcase, old_auto_option_record.name.downcase)
            replace_log << "Appointment: #{appt.id} Con: #{con} Replacing #{old_auto_option_record.auto_year.modelyear} #{old_auto_option_record.auto_manufacturer.name} #{old_auto_option_record.auto_model.name} #{old_auto_option_record.name}"
            replace_log << "                                         with #{best_guess.auto_year.modelyear} #{best_guess.auto_manufacturer.name} #{best_guess.auto_model.name} #{best_guess.name}"
            replace_log << " "
            appt.update_column(:auto_year_id, best_guess.auto_year.id)
            appt.update_column(:auto_model_id, best_guess.auto_model.id)
            appt.update_column(:auto_manufacturer_id, best_guess.auto_manufacturer.id)
            appt.update_column(:auto_option_id, best_guess.id)
          else
            replace_log << "Appointment: #{appt.id} Could not find suitable replacement for #{old_auto_option_record.auto_year.modelyear} #{old_auto_option_record.auto_manufacturer.name} #{old_auto_option_record.auto_model.name} #{old_auto_option_record.name} - deleting vehicle"
            replace_log << " "
            appt.update_column(:auto_year_id, nil)
            appt.update_column(:auto_model_id, nil)
            appt.update_column(:auto_manufacturer_id, nil)
            appt.update_column(:auto_option_id, nil)
          end
        end
      rescue Exception => e 
        replace_log <<"Exception trying to update old search #{e.to_s} - Search ID: #{appt.id}"
        puts "Exception trying to update old #{e.to_s}"
      end
    end
    return replace_log
end

def email_log(log)
  sys = ""
  if Rails.env.production?
    sys = "Production"
  elsif Rails.env.staging?
    sys = "Staging"
  else
    sys = "Test"
  end
  ActionMailer::Base.mail(:from => "mail@treadhunter.com", 
        :to => system_process_completion_email_address(),
        :subject => "#{sys}: Processed Walmart Vehicle data", 
        :body => log.join("\n")).deliver
end

namespace :ScrapeWalmart do
  desc "test stuff"
  task test_replacer: :environment do
    log = replace_appointment_vehicles(DateTime.new(2015, 07, 15))
    email_log(log)
  end

  desc "Daily load of tire data from Walmart"
  task get_tire_data: :environment do
    begin
      cur_day_of_month = Time.now.day
      if ![1, 16, 18].include?(cur_day_of_month)
        not_running_log = []
        not_running_log << "Not running because it's not the first or sixteenth of the month."

        email_log(not_running_log)

        next
      end

      TireSize.find_or_create_by_sizestr("205/70R13")
      TireSize.find_or_create_by_sizestr("175/75R13")
      TireSize.find_or_create_by_sizestr("185/65R15")
      TireSize.find_or_create_by_sizestr("165/75R13")
      TireSize.find_or_create_by_sizestr("195/70R14")
      TireSize.find_or_create_by_sizestr("185/70R14")
      TireSize.find_or_create_by_sizestr("185/65R14")
      TireSize.find_or_create_by_sizestr("195/65R15")
      TireSize.find_or_create_by_sizestr("185/60R14")
      TireSize.find_or_create_by_sizestr("175/70R14")
      TireSize.find_or_create_by_sizestr("175/70R13")
      

      @start_time = Time.now
      @skip_manu_list = ["Bertone", "Sterling", "Bugatti", "VPG", "Coda", "SRT", "Freightliner"]
      @total_error_count = 0
      @manu_not_found = []
      @model_not_found = []
      @sizes_not_found = []
      @create_records = true
      @found = @not_found = 0
      @total_processed = 0
      @manu_processed = []

      @test_mode = false

      if Rails.env.production?
        pool = Thread.pool(8)
      elsif Rails.env.staging?
        pool = Thread.pool(2)
      else
        pool = Thread.pool(4)
      end

      (1983..Time.now.year).each do |year|
      #(2005..2005).each do |year|
        sleep(5)
        pool.process {
          year_url = "http://www.walmart.com/search/finder-getnext/tire?year=#{year}"
          JSON_year_data = ReadJSONData(year_url)
          if JSON_year_data.nil?
            @total_error_count += 1
          elsif JSON_year_data == "INTERRUPT"
            return
          else
            puts "High level value values found #{JSON_year_data['value']['values'].size}"
            JSON_year_data["value"]["values"].each do |v1|
              # v1 is an array of letter ranges and the manufacturers starting with those letters
              v1["values"].each do |v2|
                # v2 is a hash of letters within the v1 range
                v2["values"].each do |manu|
                  puts "Found #{year} #{manu}"
                end
              end
            end
            JSON_year_data["value"]["values"].each do |v1|
              v1["values"].each do |v2|                
                v2["values"].each do |manu|
                  manu = TranslateManuName(manu)
                  if !@skip_manu_list.include?(manu)
                    if !@manu_processed.include?(manu)
                      @manu_processed << manu 
                    end
                    ## puts "#{year} #{manu}"
                    manu_record = AutoManufacturer.find(:first, :conditions => ["name ilike ?", manu])
                    if (@create_records) && manu_record.nil?
                      manu_record = AutoManufacturer.create(:name => manu)
                    end
                    if manu_record.nil?
                      if !@manu_not_found.include?(manu)
                        @manu_not_found << manu 
                      end
                    else
                      if manu_record.name != manu 
                        # probably an upper/lower case thing, we'll update the database name to match
                        manu_record.update_attribute(:name, manu)
                      else
                        manu_record.update_attribute(:updated_at, Time.now)
                      end

                      # Now process each manu for that year and get the models
                      make_url = "http://www.walmart.com/search/finder-getnext/tire?year=#{year}&make=#{URI.escape(manu).gsub(/\&/, '%26')}"
                      JSON_make_data = ReadJSONData(make_url)
                      if JSON_make_data.nil?
                        @total_error_count += 1
                      elsif JSON_make_data == "INTERRUPT"
                        return
                      else
                        JSON_make_data["value"]["values"].each do |model|
                          model_record = AutoModel.find(:first, :conditions => ["auto_manufacturer_id = ? and name ilike ?", manu_record.id, model])
                          if @create_records && model_record.nil?
                            model_record = AutoModel.create(:auto_manufacturer_id => manu_record.id, :name => model)
                          end
                          if model_record.nil?
                            if !@model_not_found.include?("#{manu} #{model}")
                              @model_not_found << "#{manu} #{model}"
                            end
                          else
                            if model_record.name != model
                              model_record.update_attribute(:name, model)
                            else
                              model_record.update_attribute(:updated_at, Time.now)
                            end
                            year_record = AutoYear.find(:first, :conditions => ["modelyear = ? and auto_model_id = ?", year.to_s, model_record.id])
                            if @create_records && year_record.nil?
                              year_record = AutoYear.create(:modelyear => year.to_s, :auto_model_id => model_record.id)
                            end
                            if year_record.nil?
                            else
                              @total_processed += 1
                              if (@total_processed % 100) == 0
                                puts "Processing record #{@total_processed}..."
                              end

                              year_record.update_attribute(:updated_at, Time.now)

                              options_url = "http://www.walmart.com/search/finder-getnext/tire?year=#{year}&make=#{URI.escape(manu).gsub(/\&/, '%26')}&model=#{URI.escape(model).gsub(/\&/, '%26')}"
                              JSON_options_data = ReadJSONData(options_url)
                              if JSON_options_data.nil?
                                @total_error_count += 1
                              elsif JSON_options_data == "INTERRUPT"
                                return
                              else
                                JSON_options_data["value"]["values"].each do |option|
                                  puts "#{year} #{manu} #{model}/#{option}/(#{!year_record.nil?})"                                
                                  option_record = AutoOption.find(:first, :conditions => ["auto_year_id = ? and name ilike ?", year_record.id, option])
                                  if @create_records && option_record.nil?
                                    option_record = AutoOption.create(:name => option, :auto_year_id => year_record.id)
                                  end

                                  if option_record.nil?
                                    @not_found += 1
                                  else
                                    option_record.update_attribute(:updated_at, Time.now)
                                    @found += 1

                                    size_url = "http://www.walmart.com/search/finder-getnext/tire?year=#{year}&make=#{URI.escape(manu).gsub(/\&/, '%26')}&model=#{URI.escape(model).gsub(/\&/, '%26')}&submodel=#{URI.escape(option).gsub(/\&/, '%26')}"
                                    JSON_size_data = ReadJSONData(size_url)
                                    if JSON_size_data.nil?
                                      @total_error_count += 1
                                    elsif JSON_size_data == "INTERRUPT"
                                      return
                                    else
                                      begin
                                        sizestr = JSON_size_data["value"]["values"].first["values"].first["values"].first["tireSize"]
                                      rescue
                                        sizestr = "not_provided"
                                      end
                                      ar = /(|P|LT|Z| )(\d{3})\/(\d{2})(R|ZR|VR|SR|RF|ZRF|HR|SR|TR)(\d{2}(\.5)*)(\/*\w*)/.match(sizestr)
                                      if ar
                                        sizestr = "#{ar[2]}/#{ar[3]}R#{ar[5]}"

                                        size_record = TireSize.find_by_sizestr(sizestr)
                                        puts "      #{sizestr} (#{!size_record.nil?})"
                                        if size_record.nil? && !@sizes_not_found.include?(sizestr)
                                          @sizes_not_found << sizestr
                                          if option_record.created_at >= @start_time
                                            option_record.delete
                                          end
                                        else 
                                          option_record.tire_size_id = size_record.id 
                                          option_record.save
                                        end                                        
                                      else
                                        puts "Could not match #{sizestr}"
                                      end
                                    end
                                  end
                                end
                              end
                            end
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        }
      end

      pool.shutdown

      #####################################
      @end_time = Time.now
      elapsed_seconds = (@end_time - @start_time).to_i

      log = []

      @manu_not_found.each do |m|
        log << "Could not find manu #{m}"
      end
      @model_not_found.each do |m|
        log << "Could not find model #{m}"
      end
      log << "Total already found: #{@found}"
      log << "Total not found: #{@not_found}"
      log << "-----------------------------"
      log << "Manufacturers processed:"
      @manu_processed.each do |m|
        log << "     #{m}"
      end
      log << "-----------------------------"
      log << "Sizes not found:"
      @sizes_not_found.each do |s|
        puts "     #{s}"
      end
      log << "-----------------------------"
      log << "Total processing time: #{elapsed_seconds / 60} minutes, #{elapsed_seconds % 60} seconds #{elapsed_seconds}"
      log << "Total errors: #{@total_error_count}"
      log << " "

      log << replace_tire_search_vehicles(@start_time)

      log << replace_appointment_vehicles(@start_time)


      if @test_mode
        # not going to delete these right now because need for testing appointment/search stuff
        if true
          new_options = AutoOption.find(:all, :conditions => ["created_at >= ?", @start_time])
          log << "Test mode: deleting #{new_options.size} options records..."
          new_options.each do |o|
            o.delete
          end

          new_years = AutoYear.find(:all, :conditions => ["created_at >= ?", @start_time])
          log << "Test mode: deleting #{new_years.size} year records..."
          new_years.each do |y|
            y.delete
          end

          new_models = AutoModel.find(:all, :conditions => ["created_at >= ?", @start_time])
          log << "Test mode: deleting #{new_models.size} model records..."
          new_models.each do |m|
            m.delete
          end
        end
      else
        # not test mode....gotta delete anything not attached to anything else that hasn't been updated
        replace_tire_search_vehicles(@start_time)
        replace_appointment_vehicles(@start_time)

        old_options = AutoOption.find(:all, :conditions => ["updated_at < ?", @start_time])
        log << "Live mode: deleting #{old_options.size} options records..."
        old_options.each do |o|
          o.delete
        end

        old_years = AutoYear.find(:all, :conditions => ["updated_at < ?", @start_time])
        log << "Live mode: deleting #{old_years.size} year records..."
        old_years.each do |y|
          y.delete
        end

        old_models = AutoModel.find(:all, :conditions => ["updated_at < ?", @start_time])
        log << "Live mode: deleting #{old_models.size} model records..."
        old_models.each do |m|
          m.delete
        end
      end

      email_log(log)

    rescue Interrupt => e
      puts "interrupted"
    end
  end

  desc "Add BMW stuff"
  task BMW530: :environment do
    manu = AutoManufacturer.find_by_name("BMW")
    model = AutoModel.find_by_auto_manufacturer_id_and_name(manu.id, "530i")
    option = "Sedan"
    ts = TireSize.find_by_sizestr("225/50R17")
    ["2004"].each do |year|
      puts "#{year}"
      
      auto_year = AutoYear.find_or_create_by_modelyear_and_auto_model_id(year, model.id)
      
      auto_option = AutoOption.find_or_create_by_auto_year_id_and_name(auto_year.id, option)
      auto_option.tire_size_id = ts.id
      auto_option.save
    end
    
    ts = TireSize.find_by_sizestr("225/55R16")
    ["2003", "2002", "2001", "2000"].each do |year|
      puts "#{year}"
      
      auto_year = AutoYear.find_or_create_by_modelyear_and_auto_model_id(year, model.id)
      
      auto_option = AutoOption.find_or_create_by_auto_year_id_and_name(auto_year.id, option)
      auto_option.tire_size_id = ts.id
      auto_option.save
    end
    
    ts = TireSize.find_by_sizestr("225/60R15")
    ["1996", "1995", "1994", "1993"].each do |year|
      puts "#{year}"
      
      auto_year = AutoYear.find_or_create_by_modelyear_and_auto_model_id(year, model.id)
      
      auto_option = AutoOption.find_or_create_by_auto_year_id_and_name(auto_year.id, option)
      auto_option.tire_size_id = ts.id
      auto_option.save
    end
  end

  desc "Get OEM tire data from Walmart"
  task populate: :environment do
    # first, delete existing data so we don't have conflicts.
    #AutoYear.delete_all
    #AutoOption.delete_all
    #AutoModel.delete_all
    #AutoManufacturer.delete_all
        
    create_mode = true

    years = ["2013"
              #"2012", "2011", "2010", "2009", "2008", "2007","2006", 
              #"2005", "2004", "2003", "2002", "2001", "2000",
              #"1999", "1998", "1997", "1996", 
              #"1995", "1994", "1993",
              #"1992", "1991", "1990", "1989", "1988", "1987", "1986"
            ]

    #makes = ["ACURA","ALFA ROMEO","AMC/RENAULT","AMERICAN MOTORS",
    #        "ASTON MARTIN","AUDI","AVANTI","BENTLEY","BERTONE","BMW",
    #        "BUICK","CADILLAC","CHEVROLET","CHRYSLER","DAEWOO",
    #        "DAIHATSU","DODGE","EAGLE","FERRARI","FIAT","FORD",
    #        "FREIGHTLINER","GEO","GMC","HONDA","HUMMER","HYUNDAI",
    #        "INFINITI","ISUZU","JAGUAR","JEEP","KIA","LAMBORGHINI",
    #        "LAND ROVER","LEXUS","LINCOLN","LOTUS","MASERATI",
    #        "MAYBACH","MAZDA","MERCEDES-BENZ","MERCURY","MINI",
    #        "MITSUBISHI","NISSAN","OLDSMOBILE","PANOZ","PEUGEOT",
    #        "PLYMOUTH","PONTIAC","PORSCHE","RAM","RENAULT","ROLLS ROYCE",
    #        "SAAB","SATURN","SCION","SMART","STERLING","SUBARU",
    #        "SUZUKI","TOYOTA","VOLKSWAGEN","VOLVO","YUGO"]
                
    makes = ["Acura","Alfa Romeo","Aston Martin","Audi",
            "BMW","Bentley","Buick","Cadillac","Chevrolet","Chrysler",
            "Daewoo","Daihatsu","Dodge","Eagle","Ferrari","Fiat",
            "Ford","GMC","Geo","Honda","Hummer","Hyundai","Infiniti","Isuzu",
            "Jaguar","Jeep","Kia","Lamborghini","Land Rover","Lexus","Lincoln",
            "Lotus","MINI","Maserati","Maybach","Mazda","Mercedes-Benz",
            "Mercury","Mitsubishi","Nissan","Oldsmobile","Panoz","Plymouth",
            "Pontiac","Porsche","RAM","Rolls Royce","Saab","Saturn","Scion","Smart",
            "Subaru","Suzuki","Tesla","Toyota","Volkswagen","Volvo"]

    years.each do |year|
      makes.each do |make|
        auto_manu = AutoManufacturer.where("LOWER(name) LIKE ?", make.downcase).first

        if auto_manu.nil?
          puts "*** COULD NOT FIND MANUFACTURER #{make}"
          if false
            auto_manu = AutoManufacturer.new
            auto_manu.name = make
            auto_manu.save
          else
            next
          end
        end
                
        # post to modelByYearAndMakeAction.do page
        # to get a list of models for that year/manu
        #models_url = "http://www.walmart.com/catalog/modelByYearAndMakeAction.do?year=#{year}&make=#{make}"
        models_url = "http://www.walmart.com/finder/manufactured_tires/make_year_model_tire_size_selections.json?make=#{make}&year=#{year}"
        models_url = URI::encode(models_url)

        # try up to 5 times in case we have some sort
        # of network burp
        models = []
        (1..5).each do |i|
          begin
            #puts models_url
            models_response = ReadData(models_url)
            if models_response != ''
              all_data = JSON.parse(models_response)
              models = all_data["model_series"]
            end
            break
          rescue Exception => e
            puts "Error: #{e.to_s} - try again"
            puts models_url
          end
        end

        # do we have models?
        if models.count > 0
          models.each do |model|
            auto_model = AutoModel.where("auto_manufacturer_id = ? AND LOWER(name) LIKE ?", auto_manu.id, model.downcase).first

            if auto_model.nil? 
              puts "*** COULD NOT FIND MODEL (#{make}) #{model}"
              if create_mode
                auto_model = AutoModel.new
                auto_model.auto_manufacturer_id = auto_manu.id
                auto_model.name = model
                auto_model.save
              else
                next
              end
            elsif auto_model.name != model
              puts "*** Need to Update Model name from (#{auto_model.name}) to (#{model})"
              if create_mode
                auto_model.name = model
                auto_model.save
              end
            end

            auto_year = AutoYear.find_or_create_by_modelyear_and_auto_model_id(year, auto_model.id)

            options_url = "http://www.walmart.com/finder/manufactured_tires/make_year_model_tire_size_selections.json?make=#{make}&year=#{year}&model_series=#{model}"
            options_url = URI::encode(options_url)
            options_response = ''
            options = []
            (1..5).each do |i|
              begin
                options_response = ReadData(options_url)
                if options_response != ''
                  options_data = JSON.parse(options_response)
                  options = options_data["model_lines"]
                end
                break
              rescue Exception => e 
                puts "Error: #{e.to_s} - try again"
              end
            end
            if options.count > 0
              options.each do |option|
                size_url = "http://www.walmart.com/finder/manufactured_tires/make_year_model_tire_size_selections.json?make=#{make}&year=#{year}&model_series=#{model}&model_line=#{option}"
                size_url = URI::encode(size_url)
                size_response = ''
                sizes = []
                (1..5).each do |i|
                  begin
                    size_response = ReadData(size_url)
                    if size_response != ''
                      size_data = JSON.parse(size_response)
                      sizes = size_data["tire_sizes"]
                    end
                    break
                  rescue Exception => e 
                    puts "Error: #{e.to_s} - try again"
                  end
                end
                if sizes.count > 0
                  #sizes.each do |size|
                  size = sizes.first
                  begin
                    tire_size = TireSize.find_by_sizestr(size)
                    if tire_size.nil?
                      puts "*** COULD NOT FIND SIZE #{size}"
                      next
                    end

                    auto_option = AutoOption.find_by_auto_year_id_and_name(auto_year.id, option)

                    if auto_option.nil?
                      puts "*** could not find #{year} #{make} #{model} #{option}"

                      if create_mode
                        auto_option = AutoOption.new
                        auto_option.auto_year_id = auto_year.id
                        auto_option.name = option
                        auto_option.tire_size_id = tire_size.id
                        auto_option.save
                        puts "Created"
                      end
                    else
                      puts "ALREADY HAVE #{year} #{make} #{model} #{option}"
                    end
                  end
                  else
                    puts "*no sizes*"
                  end
                end
              else
                puts "Zero options #{options_url}"
              end
            end
          else
            puts "No models found (#{make})."
          end
        end
      end
    end
end
