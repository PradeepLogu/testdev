# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "redirect"
  s.version = "0.4.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Petrik de Heus"]
  s.date = "2011-12-26"
  s.description = "Redirect is a simple Ruby redirect DSL build on Rack. It's like a simple Ruby mod_rewrite, so you can write and test your redirects in Ruby."
  s.email = ["FIX@email.com"]
  s.executables = ["redirect_app"]
  s.files = ["bin/redirect_app"]
  s.homepage = "http://github.com/p8/redirect/tree/master"
  s.require_paths = ["lib"]
  s.rubyforge_project = "redirect"
  s.rubygems_version = "2.0.3"
  s.summary = "Redirect is a simple Ruby redirect DSL build on Rack"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rack>, [">= 1.3.4", "~> 1.3"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
    else
      s.add_dependency(%q<rack>, [">= 1.3.4", "~> 1.3"])
      s.add_dependency(%q<rspec>, [">= 0"])
    end
  else
    s.add_dependency(%q<rack>, [">= 1.3.4", "~> 1.3"])
    s.add_dependency(%q<rspec>, [">= 0"])
  end
end
