require 'nokogiri'
require 'open-uri'

def ReadData(url)
    RestClient.get url, :user_agent => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) "
    #open(url, :proxy => "http://54.243.138.45:80", "User-Agent" => "Mozilla/5.0 (Windows; U; Windows NT 5.1; de; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 (FM Scene 4.6.1) ").read
end

def process_general_data(create_records)
    manu = TireManufacturer.find_or_create_by_name('General')

    model_xref = {}
    #model_xref(old) = new
    #model_xref['P6000 Sport Veloce'] = 'P6000'
    #model_xref['Scorpion Verde All Season'] = 'Scorpion Verde A/S'
    #rename_existing_model(manu.id, "H101 Ventus", "Ventus H101", true) #create_records)
    TireSize.find_or_create_by_sizestr('285/75R24')
    TireSize.find_or_create_by_sizestr('295/75R22')
    TireSize.find_or_create_by_sizestr('225/70R19')
    TireSize.find_or_create_by_sizestr('245/70R19')
    TireSize.find_or_create_by_sizestr('255/70R22')

    process_simpletire(manu.id, "http://simpletire.com/general-tires", create_records, model_xref)
end

def process_hankook_data(create_records)
    manu = TireManufacturer.find_or_create_by_name('Hankook')

    model_xref = {}
    #model_xref(old) = new
    model_xref["Optimo H725A-B"] = 'Optimo H725A'
    #model_xref['P6000 Sport Veloce'] = 'P6000'
    #model_xref['Scorpion Verde All Season'] = 'Scorpion Verde A/S'
    rename_existing_model(manu.id, "H101 Ventus", "Ventus H101", true) #create_records)
    rename_existing_model(manu.id, "H105 Ventus V4 ES", "Ventus HR II H405", true) #create_records)
    rename_existing_model(manu.id, "Ventus V4 ES H105", "H405 Ventus HR II", create_records)
    rename_existing_model(manu.id, "H406 Radial", "Radial H406", true) #create_records)
    rename_existing_model(manu.id, "H411 Optimo", "Optimo H411", true) #create_records)
    rename_existing_model(manu.id, "H417 Optimo", "Optimo H417", true) #create_records)
    rename_existing_model(manu.id, "H418 Optimo", "Optimo H418", true) #create_records)
    rename_existing_model(manu.id, "H426 Optimo 4 Groove", "Optimo H426 4 Groove", true) #create_records)
    rename_existing_model(manu.id, "H431 Optimo", "Optimo H431", true) #create_records)
    rename_existing_model(manu.id, "H437 Ventus V2 Concept", "Ventus V2 Concept H437", true) #create_records)
    rename_existing_model(manu.id, "H714 Radial 3 Groove", "Radial H714 3 Groove", true) #create_records)
    rename_existing_model(manu.id, "H714 Radial 4 Groove", "Radial H714 4 Groove", true) #create_records)
    rename_existing_model(manu.id, "H724 Optimo", "Optimo H724", true) #create_records)
    rename_existing_model(manu.id, "H725 Mileage Plus II", "Mileage Plus II H725", true) #create_records)
    rename_existing_model(manu.id, "H725 Optimo", "Optimo H725", true) #create_records)
    rename_existing_model(manu.id, "H725A Optimo A Type", "Optimo H725A", true) #create_records)
    rename_existing_model(manu.id, "H727 Optimo", "Optimo H727", true) #create_records)
    rename_existing_model(manu.id, "K104 Ventus Sport", "Ventus Sport K104", true) #create_records)
    rename_existing_model(manu.id, "K106 Radial", "Radial K106", true) #create_records)
    rename_existing_model(manu.id, "K110 Ventus V12 evo", "Ventus V12 evo K110", true) #create_records)
    rename_existing_model(manu.id, "RA07 Radial", "Radial RA07", true) #create_records)
    rename_existing_model(manu.id, "RF08 Dynapro AT", "Dynapro AT RF08", true) #create_records)
    rename_existing_model(manu.id, "RF10 P-Metric Dynapro AT-M", "Dynapro ATM RF10", true) #create_records)
    rename_existing_model(manu.id, "RH03 P-Metric Dynapro AS", "Dynapro AS RH03", true) #create_records)
    rename_existing_model(manu.id, "RH06 Ventus ST", "Ventus ST RH06", true) #create_records)
    rename_existing_model(manu.id, "RH07 Ventus AS", "Ventus AS RH07", true) #create_records)
    rename_existing_model(manu.id, "RH12 P-Metric Dynapro HT", "Dynapro HT RH12", true) #create_records)
    rename_existing_model(manu.id, "RT03 Dynapro MT", "Dynapro MT RT03", true) #create_records)
    rename_existing_model(manu.id, "RW07 Dynapro i*Pike", "Dynapro i*pike RW07", true) #create_records)
    rename_existing_model(manu.id, "RW11 i*pike", "i*pike RW11", true) #create_records)
    rename_existing_model(manu.id, "W300 ICEBEAR", "Icebear W300", true) #create_records)
    rename_existing_model(manu.id, "W310 Winter i*cept evo", "Winter i*cept evo W310", true) #create_records)
    rename_existing_model(manu.id, "W401 Zovac HP", "Zovac HP W401", true) #create_records)
    rename_existing_model(manu.id, "W409 Winter i*Pike", "Winter i*pike W409", true) #create_records)

    #TireSize.find_or_create_by_sizestr('335/25R22')
    #TireSize.find_or_create_by_sizestr('355/30R19')
    #TireSize.find_or_create_by_sizestr('305/30R22')
    #TireSize.find_or_create_by_sizestr('375/20R21')
    #TireSize.find_or_create_by_sizestr('265/25R23')
    #TireSize.find_or_create_by_sizestr('275/25R26')
    #TireSize.find_or_create_by_sizestr('405/25R24')
    #TireSize.find_or_create_by_sizestr('355/25R19')
    #TireSize.find_or_create_by_sizestr('285/45R18')
    #TireSize.find_or_create_by_sizestr('295/25R26')
    #TireSize.find_or_create_by_sizestr('315/40R25')
    #TireSize.find_or_create_by_sizestr('315/30R30')

    process_simpletire(manu.id, "http://simpletire.com/hankook-tires", create_records, model_xref)
end

namespace :ScrapeHankook do
    desc "Create tire manufacturers data from Hankook"
    task populate: :environment do
        puts Benchmark.measure {
            process_hankook_data(true)
        }
    end

    task test: :environment do
        puts Benchmark.measure {
            process_hankook_data(false)
        }
    end
end


namespace :ScrapeGeneral do
    desc "Create tire manufacturers data from General"
    task populate: :environment do
        puts Benchmark.measure {
            process_general_data(true)
        }
    end

    task test: :environment do
        puts Benchmark.measure {
            process_general_data(false)
        }
    end
end
