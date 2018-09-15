require 'bundler'

Bundler.setup
$:.unshift File.expand_path('../lib', __FILE__)

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'docker_task'
require 'packtory'

RSpec::Core::RakeTask.new('spec')
task :default => :spec

task :spec_all do
  ENV['INCLUDE_PACK_EXTRA_SPECS'] = '1'
  ENV['INCLUDE_INSTALL_SPECS'] = '1'

  Rake::Task['spec'].invoke
end

docker_run = lambda do |task, opts|
  opts << '-v %s:/build' % File.expand_path('../', __FILE__)
  opts
end

DockerTask.create({ :remote_repo => 'ruby',
                    :pull_tag => '2.5.1',
                    :image_name => 'packtory.ruby251',
                    :run => docker_run })

DockerTask.include_tasks(:use => 'packtory.ruby251')

desc 'Bash to ruby251 environment'
task :bash_to_ruby251 do
  c = DockerTask.containers['packtory.ruby251']
  c.runi
end

desc 'Craete a Debian package'
task :pack_deb do
  cmd = 'env PACKAGE_OUTPUT=%s BUNDLE_GEMFILE=%s BUNDLER_INCLUDE=1 bin/packtory %s' %
        [ ENV['PACK_PACKAGE_OUTPUT'] || 'deb',
          File.expand_path('../Gemfile.system', __FILE__),
          File.expand_path('../', __FILE__) ]

  puts cmd
  Bundler.clean_system(cmd)
end

desc 'Create an RPM package'
task :pack_rpm do
  ENV['PACK_PACKAGE_OUTPUT'] = 'rpm'
  Rake::Task['pack_deb'].invoke
end
