# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "fuzzy-string-match"
  s.version = "0.9.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Kiyoka Nishiyama"]
  s.date = "2013-03-26"
  s.description = "calculate Jaro Winkler distance."
  s.email = "kiyoka@sumibi.org"
  s.extra_rdoc_files = ["LICENSE.txt", "README.md"]
  s.files = ["LICENSE.txt", "README.md"]
  s.homepage = "http://github.com/kiyoka/fuzzy-string-match"
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.1")
  s.rubygems_version = "1.8.24"
  s.summary = "fuzzy string matching library"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>, [">= 0"])
      s.add_runtime_dependency(%q<RubyInline>, [">= 3.8.6"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
      s.add_runtime_dependency(%q<RubyInline>, [">= 3.8.6"])
    else
      s.add_dependency(%q<rspec>, [">= 0"])
      s.add_dependency(%q<RubyInline>, [">= 3.8.6"])
      s.add_dependency(%q<rspec>, [">= 0"])
      s.add_dependency(%q<RubyInline>, [">= 3.8.6"])
    end
  else
    s.add_dependency(%q<rspec>, [">= 0"])
    s.add_dependency(%q<RubyInline>, [">= 3.8.6"])
    s.add_dependency(%q<rspec>, [">= 0"])
    s.add_dependency(%q<RubyInline>, [">= 3.8.6"])
  end
end
