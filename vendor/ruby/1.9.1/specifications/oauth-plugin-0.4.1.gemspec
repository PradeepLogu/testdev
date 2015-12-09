# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "oauth-plugin"
  s.version = "0.4.1"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1") if s.respond_to? :required_rubygems_version=
  s.authors = ["Pelle Braendgaard"]
  s.date = "2011-10-20"
  s.description = "Rails plugin for implementing an OAuth Provider or Consumer"
  s.email = "oauth-ruby@googlegroups.com"
  s.extra_rdoc_files = ["README.rdoc"]
  s.files = ["README.rdoc"]
  s.homepage = "http://github.com/pelle/oauth-plugin"
  s.require_paths = ["lib"]
  s.rubyforge_project = "oauth"
  s.rubygems_version = "1.8.24"
  s.summary = "Ruby on Rails Plugin for OAuth Provider and Consumer"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<opentransact>, [">= 0"])
      s.add_development_dependency(%q<rspec>, ["~> 2.4.0"])
      s.add_development_dependency(%q<fakeweb>, [">= 0"])
      s.add_development_dependency(%q<fuubar>, [">= 0"])
      s.add_development_dependency(%q<guard-rspec>, [">= 0"])
      s.add_development_dependency(%q<growl>, [">= 0"])
      s.add_development_dependency(%q<rack-test>, [">= 0"])
      s.add_runtime_dependency(%q<multi_json>, [">= 0"])
      s.add_runtime_dependency(%q<oauth>, ["~> 0.4.4"])
      s.add_runtime_dependency(%q<rack>, [">= 0"])
      s.add_runtime_dependency(%q<oauth2>, [">= 0.5.0"])
    else
      s.add_dependency(%q<opentransact>, [">= 0"])
      s.add_dependency(%q<rspec>, ["~> 2.4.0"])
      s.add_dependency(%q<fakeweb>, [">= 0"])
      s.add_dependency(%q<fuubar>, [">= 0"])
      s.add_dependency(%q<guard-rspec>, [">= 0"])
      s.add_dependency(%q<growl>, [">= 0"])
      s.add_dependency(%q<rack-test>, [">= 0"])
      s.add_dependency(%q<multi_json>, [">= 0"])
      s.add_dependency(%q<oauth>, ["~> 0.4.4"])
      s.add_dependency(%q<rack>, [">= 0"])
      s.add_dependency(%q<oauth2>, [">= 0.5.0"])
    end
  else
    s.add_dependency(%q<opentransact>, [">= 0"])
    s.add_dependency(%q<rspec>, ["~> 2.4.0"])
    s.add_dependency(%q<fakeweb>, [">= 0"])
    s.add_dependency(%q<fuubar>, [">= 0"])
    s.add_dependency(%q<guard-rspec>, [">= 0"])
    s.add_dependency(%q<growl>, [">= 0"])
    s.add_dependency(%q<rack-test>, [">= 0"])
    s.add_dependency(%q<multi_json>, [">= 0"])
    s.add_dependency(%q<oauth>, ["~> 0.4.4"])
    s.add_dependency(%q<rack>, [">= 0"])
    s.add_dependency(%q<oauth2>, [">= 0.5.0"])
  end
end
