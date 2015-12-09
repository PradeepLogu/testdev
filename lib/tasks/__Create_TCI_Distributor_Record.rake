namespace :CreateTCIDistributor do
	desc "Create distributor record for TCI"
	task populate: :environment do
		distributor = Distributor.find_or_create_by_distributor_name('Tire Centers, LLC')
		distributor.address = '300 Best Friend Ct'
		distributor.city = 'Norcross'
		distributor.state = 'GA'
		distributor.zipcode = '30071'
		distributor.contact_name = ''
		distributor.contact_email = ''
		distributor.tire_manufacturers = ''

		manu_list = [
						"BFGoodrich", "Continental", "General", "Hankook", 
						"Maxxis", "Michelin", "Pirelli", "Riken",
						"Uniroyal", "Yokohama"# , "Omni"
					]

		manus = TireManufacturer.where('name in (?)', manu_list).order(:name)
		if manus.count == manu_list.size
			manus.each do |m|
				distributor.add_tire_manufacturer_id(m.id)
			end

			distributor.save
		else
			puts "Couldn't find a manu..."
			puts manu_list - manus.map{|m| m.name}
		end
	end
end