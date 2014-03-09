# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'roll/version'

Gem::Specification.new do |spec|
  spec.name          = 'roll'
  spec.version       = Roll::VERSION
  spec.authors       = ['Craftsmen']
  spec.email         = ['mehdi@craftsmen.io']
  spec.summary       = 'Generate a Rails app using Craftsmen\'s best practices.'
  spec.description   = 'Roll is the base Rails application used at Craftsmen to get a jump start on a working app.'
  spec.homepage      = 'http://github.com/craftsmen/roll'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = ['roll']
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  s.required_ruby_version = '>= 1.9.2'
  s.add_dependency 'bundler', '~> 1.3'
  s.add_dependency 'rails', '4.0.0'
end
