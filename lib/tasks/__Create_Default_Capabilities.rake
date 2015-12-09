namespace :DefaultCapabilities do
    desc "Create default capabilities"
    task populate: :environment do
        c = Capability.find_or_create_by_key('FILTERPORTAL')
        c.name = 'Filter Portal'
        c.save

        c = Capability.find_or_create_by_key('SEARCHPORTAL')
        c.name = 'Search Portal'
        c.save

        c = Capability.find_or_create_by_key('POSTLISTINGS')
        c.name = 'Post Listings'
        c.save

        c = Capability.find_or_create_by_key('BRANDING')
        c.name = 'Branding'
        c.save

        c = Capability.find_or_create_by_key('LOGO')
        c.name = 'Logo'
        c.save

        c = Capability.find_or_create_by_key('MOBILE')
        c.name = 'Mobile'
        c.save

    end
end