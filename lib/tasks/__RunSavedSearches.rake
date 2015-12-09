namespace :RunSavedSearches do
    desc "Run saved searches"
    task execute: :environment do
		s = SavedSearchManager.new
		s.process
	end
end