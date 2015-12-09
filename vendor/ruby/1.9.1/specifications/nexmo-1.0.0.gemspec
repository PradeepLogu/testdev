# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "nexmo"
  s.version = "1.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Tim Craft"]
  s.date = "2012-11-16"
  s.description = "A simple wrapper for the Nexmo API"
  s.email = ["mail@timcraft.com"]
  s.homepage = "http://github.com/timcraft/nexmo"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.24"
  s.summary = "See description"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rake>, [">= 0.9.3"])
      s.add_development_dependency(%q<mocha>, ["~> 0.10.3"])
      s.add_development_dependency(%q<multi_json>, ["~> 1.3.6"])
    else
      s.add_dependency(%q<rake>, [">= 0.9.3"])
      s.add_dependency(%q<mocha>, ["~> 0.10.3"])
      s.add_dependency(%q<multi_json>, ["~> 1.3.6"])
    end
  else
    s.add_dependency(%q<rake>, [">= 0.9.3"])
    s.add_dependency(%q<mocha>, ["~> 0.10.3"])
    s.add_dependency(%q<multi_json>, ["~> 1.3.6"])
  end
end
