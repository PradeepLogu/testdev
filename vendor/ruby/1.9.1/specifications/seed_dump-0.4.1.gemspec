# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "seed_dump"
  s.version = "0.4.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Rob Halff"]
  s.date = "2012-08-01"
  s.description = "Dump (parts) of your database to db/seeds.rb to get a headstart creating a meaningful seeds.rb file"
  s.email = "rob.halff@gmail.com"
  s.extra_rdoc_files = ["README.rdoc"]
  s.files = ["README.rdoc"]
  s.homepage = "http://github.com/rhalff/seed_dump"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.24"
  s.summary = "{Seed Dumper for Rails}"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
