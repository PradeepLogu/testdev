# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "crypt"
  s.version = "1.1.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Richard Kernahan"]
  s.date = "2006-08-06"
  s.email = "kernighan_rich@rubyforge.org"
  s.homepage = "http://crypt.rubyforge.org/"
  s.require_paths = ["."]
  s.required_ruby_version = Gem::Requirement.new("> 0.0.0")
  s.rubyforge_project = "crypt"
  s.rubygems_version = "2.0.3"
  s.summary = "The Crypt library is a pure-ruby implementation of a number of popular encryption algorithms. Block cyphers currently include Blowfish, GOST, IDEA, and Rijndael (AES). Cypher Block Chaining (CBC) has been implemented. Twofish, Serpent, and CAST256 are planned for release soon."
end
