require 'bundler'

Bundler.setup
$:.unshift File.expand_path('../lib', __FILE__)

require 'rspec/core/rake_task'
require 'docker_task'
require 'packguy'

RSpec::Core::RakeTask.new('spec')
task :default => :spec

docker_run = lambda do |task, opts|
  opts << '-v %s:/build' % File.expand_path('../', __FILE__)
  opts
end

DockerTask.create({ :remote_repo => 'ruby',
                    :pull_tag => '2.5.1',
                    :image_name => 'packguy.ruby251',
                    :run => docker_run })

DockerTask.include_tasks(:use => 'packguy.ruby251')

desc 'Bash to ruby251 environment'
task :bash_to_ruby251 do
  c = DockerTask.containers['packguy.ruby251']
  c.runi
end
