# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'wowlog/version'

Gem::Specification.new do |spec|
  spec.name          = "wowlog"
  spec.version       = Wowlog::VERSION
  spec.authors       = ["Masayoshi Mizutani"]
  spec.email         = ["muret@haeena.net"]
  spec.summary       = %q{World of Warcraft Combat Log Parser}
  spec.description   = %q{Wowlog is Parser Library for World of Warcraft Combat Log to analyze your combat.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
end
