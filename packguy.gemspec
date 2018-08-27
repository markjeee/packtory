$:.unshift File.expand_path('../lib', __FILE__)
require 'packguy/version'

Gem::Specification.new do |s|
  s.name              = 'packguy'
  s.date              = Time.now.strftime('%Y-%m-%d')
  s.version           = ENV['BUILD_VERSION'] || Packguy::VERSION
  s.summary           = 'A packguy'
  s.homepage          = 'https://gemfury.com'
  s.email             = 'hello@gemfury.com'
  s.authors           = [ "Mark John Buenconsejo" ]
  s.license           = 'MIT'

  s.executables       = %w(packguy)
  s.files             = %w(README.md) +
                        Dir.glob('bin/**/*') +
                        Dir.glob('lib/**/*')

  s.add_dependency    'bundler'

  s.description = <<DESCRIPTION
A packguy
DESCRIPTION

  s.post_install_message =<<POSTINSTALL
************************************************************************

Heyyy, thank you for using packguy. Have fun!

************************************************************************
POSTINSTALL
end
