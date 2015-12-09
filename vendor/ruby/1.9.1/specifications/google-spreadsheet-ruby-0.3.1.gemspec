# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "google-spreadsheet-ruby"
  s.version = "0.3.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Hiroshi Ichikawa"]
  s.date = "2013-01-20"
  s.description = "This is a library to read/write Google Spreadsheet."
  s.email = ["gimite+github@gmail.com"]
  s.extra_rdoc_files = ["README.rdoc"]
  s.files = ["README.rdoc"]
  s.homepage = "https://github.com/gimite/google-spreadsheet-ruby"
  s.licenses = ["New BSD"]
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.24"
  s.summary = "This is a library to read/write Google Spreadsheet."

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<google_drive>, [">= 0.3.0"])
      s.add_development_dependency(%q<rake>, [">= 0.8.0"])
    else
      s.add_dependency(%q<google_drive>, [">= 0.3.0"])
      s.add_dependency(%q<rake>, [">= 0.8.0"])
    end
  else
    s.add_dependency(%q<google_drive>, [">= 0.3.0"])
    s.add_dependency(%q<rake>, [">= 0.8.0"])
  end
end
