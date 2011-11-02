# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "knife-ninefold/version"

Gem::Specification.new do |s|
  s.name        = "knife-ninefold"
  s.version     = Knife::Ninefold::VERSION
  s.platform    = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = ["README.rdoc", "LICENSE" ]
  s.authors     = ["Chirag Jog"]
  s.email       = ["chirag@clogeny.com"]
  s.homepage    = "https://github.com/chiragjog/knife-ninefold"
  s.summary     = %q{Ninefold Compute Support for Chef's Knife Command}
  s.description = s.summary

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "fog", "~> 1.0.0"
end
