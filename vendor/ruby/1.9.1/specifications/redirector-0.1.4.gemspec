# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "redirector"
  s.version = "0.1.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Brian Landau"]
  s.date = "2012-09-08"
  s.description = "A Rails engine that adds a piece of middleware to the top of your middleware stack that looks for redirect rules stored in your database and redirects you accordingly."
  s.email = ["brian.landau@viget.com"]
  s.homepage = "https://github.com/vigetlabs/redirector"
  s.require_paths = ["lib"]
  s.rubygems_version = "2.0.3"
  s.summary = "A Rails engine that adds a piece of middleware to the top of your middleware stack that looks for redirect rules stored in your database and redirects you accordingly."

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rails>, ["~> 3.1"])
      s.add_development_dependency(%q<mysql2>, [">= 0"])
      s.add_development_dependency(%q<rspec-rails>, [">= 0"])
      s.add_development_dependency(%q<shoulda-matchers>, [">= 0"])
      s.add_development_dependency(%q<capybara>, [">= 0"])
      s.add_development_dependency(%q<database_cleaner>, [">= 0"])
      s.add_development_dependency(%q<factory_girl_rails>, ["~> 1.7"])
    else
      s.add_dependency(%q<rails>, ["~> 3.1"])
      s.add_dependency(%q<mysql2>, [">= 0"])
      s.add_dependency(%q<rspec-rails>, [">= 0"])
      s.add_dependency(%q<shoulda-matchers>, [">= 0"])
      s.add_dependency(%q<capybara>, [">= 0"])
      s.add_dependency(%q<database_cleaner>, [">= 0"])
      s.add_dependency(%q<factory_girl_rails>, ["~> 1.7"])
    end
  else
    s.add_dependency(%q<rails>, ["~> 3.1"])
    s.add_dependency(%q<mysql2>, [">= 0"])
    s.add_dependency(%q<rspec-rails>, [">= 0"])
    s.add_dependency(%q<shoulda-matchers>, [">= 0"])
    s.add_dependency(%q<capybara>, [">= 0"])
    s.add_dependency(%q<database_cleaner>, [">= 0"])
    s.add_dependency(%q<factory_girl_rails>, ["~> 1.7"])
  end
end
