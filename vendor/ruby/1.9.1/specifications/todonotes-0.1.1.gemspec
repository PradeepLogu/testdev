# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "todonotes"
  s.version = "0.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Knut Lickert"]
  s.date = "2012-12-02"
  s.description = "todonotes.\nSupport programming by fixme/todo commands.\n\nGem based on a proposal in http://forum.ruby-portal.de/viewtopic.php?f=11&t=11957\n"
  s.email = "knut@lickert.net"
  s.extra_rdoc_files = ["readme.rdoc"]
  s.files = ["readme.rdoc"]
  s.homepage = "http://rubypla.net/todonotes"
  s.rdoc_options = ["lib/**/*.rb", "--main readme.rdoc"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.24"
  s.summary = "Support programming by todonotes/todo commands."

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<log4r>, [">= 0"])
    else
      s.add_dependency(%q<log4r>, [">= 0"])
    end
  else
    s.add_dependency(%q<log4r>, [">= 0"])
  end
end
