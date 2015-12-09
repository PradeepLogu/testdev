# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "google-analytics-rails"
  s.version = "0.0.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Benoit Garret"]
  s.date = "2012-06-29"
  s.description = "Rails helpers to manage google analytics tracking"
  s.email = ["benoit.garret@gadz.org"]
  s.homepage = "https://github.com/bgarret/google-analytics-rails"
  s.require_paths = ["lib"]
  s.rubyforge_project = "google-analytics-rails"
  s.rubygems_version = "1.8.24"
  s.summary = "Rails helpers to manage google analytics tracking"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<yard>, [">= 0"])
      s.add_development_dependency(%q<redcarpet>, [">= 0"])
      s.add_development_dependency(%q<activesupport>, ["~> 3.0"])
    else
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<yard>, [">= 0"])
      s.add_dependency(%q<redcarpet>, [">= 0"])
      s.add_dependency(%q<activesupport>, ["~> 3.0"])
    end
  else
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<yard>, [">= 0"])
    s.add_dependency(%q<redcarpet>, [">= 0"])
    s.add_dependency(%q<activesupport>, ["~> 3.0"])
  end
end
