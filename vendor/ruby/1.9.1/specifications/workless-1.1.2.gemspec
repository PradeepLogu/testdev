# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "workless"
  s.version = "1.1.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.6") if s.respond_to? :required_rubygems_version=
  s.authors = ["lostboy"]
  s.date = "2011-06-30"
  s.description = "Extension to Delayed Job to enable workers to scale up when needed"
  s.email = "paul.crabtree@gmail.com"
  s.homepage = "http://github.com/lostboy/workless"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.24"
  s.summary = "Use delayed job workers only when theyre needed on Heroku"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rails>, [">= 0"])
      s.add_runtime_dependency(%q<heroku-api>, [">= 0"])
      s.add_runtime_dependency(%q<rush>, [">= 0"])
      s.add_runtime_dependency(%q<delayed_job>, [">= 2.0.7"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
    else
      s.add_dependency(%q<rails>, [">= 0"])
      s.add_dependency(%q<heroku-api>, [">= 0"])
      s.add_dependency(%q<rush>, [">= 0"])
      s.add_dependency(%q<delayed_job>, [">= 2.0.7"])
      s.add_dependency(%q<rspec>, [">= 0"])
    end
  else
    s.add_dependency(%q<rails>, [">= 0"])
    s.add_dependency(%q<heroku-api>, [">= 0"])
    s.add_dependency(%q<rush>, [">= 0"])
    s.add_dependency(%q<delayed_job>, [">= 2.0.7"])
    s.add_dependency(%q<rspec>, [">= 0"])
  end
end
