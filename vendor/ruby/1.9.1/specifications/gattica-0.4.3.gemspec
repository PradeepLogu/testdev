# -*- encoding: utf-8 -*-
# stub: gattica 0.4.3 ruby lib

Gem::Specification.new do |s|
  s.name = "gattica"
  s.version = "0.4.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["The Active Network"]
  s.date = "2010-01-29"
  s.description = "Gattica is a Ruby library for extracting data from the Google Analytics API."
  s.email = "rob.cameron@active.com"
  s.extra_rdoc_files = ["LICENSE", "README.rdoc"]
  s.files = ["LICENSE", "README.rdoc"]
  s.homepage = "http://github.com/activenetwork/gattica"
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = "2.1.4"
  s.summary = "Gattica is a Ruby library for extracting data from the Google Analytics API."

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<hpricot>, [">= 0.6.164"])
    else
      s.add_dependency(%q<hpricot>, [">= 0.6.164"])
    end
  else
    s.add_dependency(%q<hpricot>, [">= 0.6.164"])
  end
end
