# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "redirect/version"

Gem::Specification.new do |s|
  s.authors     = ["Petrik de Heus"]
  s.default_executable = %q{redirect_app}
  s.name        = "redirect"
  s.version     = Redirect::VERSION
  s.email       = ["FIX@email.com"]
  s.homepage    = "http://github.com/p8/redirect/tree/master"
  s.summary     = %q{Redirect is a simple Ruby redirect DSL build on Rack}
  s.description = %q{Redirect is a simple Ruby redirect DSL build on Rack. It's like a simple Ruby mod_rewrite, so you can write and test your redirects in Ruby.}

  s.rubyforge_project = "redirect"
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'rack', '~> 1.3', '>= 1.3.4'
  s.add_development_dependency "rspec"
end
