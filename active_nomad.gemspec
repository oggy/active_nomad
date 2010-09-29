# -*- encoding: utf-8 -*-
$:.unshift File.expand_path('lib', File.dirname(__FILE__))
require 'active_nomad/version'

Gem::Specification.new do |s|
  s.name        = 'active_nomad'
  s.date        = Date.today.strftime('%Y-%m-%d')
  s.version     = ActiveNomad::VERSION.join('.')
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["George Ogata"]
  s.email       = ["george.ogata@gmail.com"]
  s.homepage    = "http://github.com/oggy/active_nomad"
  s.summary     = "ActiveRecord objects with a customizable persistence strategy."

  s.required_rubygems_version = ">= 1.3.6"
  s.add_dependency "activerecord", "~> 2.3.0"
  s.add_development_dependency "rspec", "~> 1.3.0"
  s.files = Dir["lib/**/*"] + %w(CHANGELOG LICENSE README.markdown Rakefile)
  s.test_files = Dir["features/**/*", "spec/**/*"]
  s.extra_rdoc_files = ["LICENSE", "README.markdown"]
  s.require_path = 'lib'
  s.specification_version = 3
  s.rdoc_options = ["--charset=UTF-8"]
end
