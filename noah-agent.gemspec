# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "noah-agent/version"

Gem::Specification.new do |s|
  s.name        = "noah-agent"
  s.version     = NoahAgent::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["TODO: Write your name"]
  s.email       = ["TODO: Write your email address"]
  s.homepage    = ""
  s.summary     = %q{TODO: Write a gem summary}
  s.description = %q{TODO: Write a gem description}

  s.rubyforge_project = "noah-agent"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency("celluloid", ["= 0.2.2"])
  s.add_dependency("redis", ["= 2.2.2"])
  s.add_dependency("excon", ["= 0.7.3"])
  s.add_dependency("slop", ["= 2.1.0"])
  s.add_dependency("uuid", ["= 2.3.3"])
  s.add_dependency("multi_json", ["= 1.0.3"]) # This needs to be removed at some point for real JSON libraries.
end
