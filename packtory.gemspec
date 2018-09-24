$:.unshift File.expand_path('../lib', __FILE__)
require 'packtory/version'

Gem::Specification.new do |s|
  s.name              = 'packtory'
  s.date              = Time.now.strftime('%Y-%m-%d')
  s.version           = ENV['BUILD_VERSION'] || Packtory::VERSION
  s.summary           = 'An easy to use system packaging tool for your Ruby gems.'
  s.homepage          = 'https://gemfury.com'
  s.email             = 'hello@gemfury.com'
  s.authors           = [ "Mark John Buenconsejo" ]
  s.license           = 'MIT'

  s.executables       = %w(packtory)
  s.files             = %w(README.md) +
                        Dir.glob('bin/**/*') +
                        Dir.glob('lib/**/*')

  s.add_dependency    'bundler'
  s.add_dependency    'fpm'

  s.description = <<DESCRIPTION
An easy to use system packaging tool for your Ruby
gems. Build package for Debian, RPM, and _soon_ Homebrew, directly
from your gem repo.
DESCRIPTION

  s.post_install_message =<<POSTINSTALL
************************************************************************

Heyyy, thank you for using packtory. Have fun!

************************************************************************
POSTINSTALL
end
