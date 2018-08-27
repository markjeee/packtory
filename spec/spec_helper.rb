require 'bundler'
require 'fileutils'

ENV['BUNDLE_GEMFILE'] = File.expand_path('../../Gemfile', __FILE__)
Bundler.setup

$:.unshift File.expand_path('../../lib', __FILE__)
require 'packguy'
require 'docker_task'
require 'rspec'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end

module PackguySpec
  TMP_SPEC_GEMS = File.expand_path('../../tmp/packguy_spec/gems', __FILE__)
  TMP_SPEC_BUNDLE_WORKING_PATH = File.expand_path('../../tmp/packguy_spec/bundle', __FILE__)

  VALID_BUILD_PATH = File.expand_path('../valid_build', __FILE__)
  VENDOR_CACHE = File.expand_path('../vendor_cache', __FILE__)

  PACKGUY_PATH = File.expand_path('../../bin/packguy', __FILE__)

  SPEC_GEMS = {
    'fpm' => 'https://github.com/jordansissel/fpm/archive/master.tar.gz',
    'gemfury' => 'https://github.com/gemfury/gemfury/archive/master.tar.gz',
    'httparty' => 'https://github.com/jnunemaker/httparty/archive/master.tar.gz',
    'diff-lcs' => 'https://github.com/halostatue/diff-lcs/archive/master.tar.gz',
    'puma' => 'https://github.com/puma/puma/archive/master.tar.gz',
    'thin' => 'https://github.com/macournoyer/thin/archive/master.tar.gz'
  }

  def self.spec_gems
    SPEC_GEMS
  end

  def self.spec_gems_path
    TMP_SPEC_GEMS
  end

  def self.spec_bundle_working_path
    TMP_SPEC_BUNDLE_WORKING_PATH
  end

  def self.prepare_spec_gems_path
    FileUtils.mkpath(spec_gems_path)
  end

  def self.spec_gem_extract_path(gem_name)
    File.join(spec_gems_path, gem_name)
  end

  def self.spec_gem_archive_path(gem_name)
    File.join(spec_gems_path, '%s.tar.gz' % gem_name)
  end

  def self.copy_vendor_cache(working_path)
    target_vc_path = Pathname.new(working_path).join('vendor/cache')
    unless target_vc_path.exist?
      FileUtils.mkpath(target_vc_path)
      FileUtils.cp_r(Dir.glob('%s/*' % VENDOR_CACHE), target_vc_path)
    end

    target_vc_path
  end

  def self.packguy_setup(config = { })
    Packguy::Packer.config.merge!({ :path => VALID_BUILD_PATH,
                                    :working_path => File.join(VALID_BUILD_PATH, 'tmp_packguy_wp'),
                                    :bundler_silent => true,
                                    :bundler_local => true
                                  }.merge(config))
    Packguy::Packer.setup
    copy_vendor_cache(Packguy::Packer.config[:working_path])

    Packguy
  end

  def self.define_docker_containers
    docker_run = lambda do |task, opts|
      opts << '-v %s:/build' % File.expand_path('../../', __FILE__)
      opts
    end

    show_commands = ENV['SHOW_COMMANDS'] ? true : false

    DockerTask.create!({ :remote_repo => 'ubuntu',
                         :pull_tag => 'xenial',
                         :image_name => 'packguy-spec.xenial',
                         :run => docker_run,
                         :show_commands => show_commands
                       })

    DockerTask.create!({ :remote_repo => 'ubuntu',
                         :pull_tag => 'bionic',
                         :image_name => 'packguy-spec.bionic',
                         :run => docker_run,
                         :show_commands => show_commands
                       })

    DockerTask.create!({ :remote_repo => 'debian',
                         :pull_tag => 'jessie',
                         :image_name => 'packguy-spec.jessie',
                         :run => docker_run,
                         :show_commands => show_commands
                       })

    DockerTask.create!({ :remote_repo => 'debian',
                         :pull_tag => 'stretch',
                         :image_name => 'packguy-spec.stretch',
                         :run => docker_run,
                         :show_commands => show_commands
                       })
  end

  def self.calculate_build_path(file_path)
    root_path = File.expand_path('../../', __FILE__)
    file_path.gsub(root_path, '/build')
  end

  def self.pack(build_path, env_vars = { }, opts = { })
    env_vars['FPM_EXEC_PATH'] = `which fpm`.strip
    env_vars = env_vars.inject([]) { |a, (k,v)| a << '%s=%s' % [ k, v ]; a }.join(' ')

    cmd = 'env %s %s %s %s' %
          [ env_vars, PACKGUY_PATH, build_path, opts[:no_stdout] ? '>/dev/null 2>&1' : '' ]

    unless opts[:no_stdout]
      puts(cmd)
    end

    Bundler.clean_system(cmd)
  end

  def self.pack_with_gems(gem_name)
    env_vars = {
      'PACKGUY_BUNDLE_WORKING_PATH' => spec_bundle_working_path
    }

    pack(spec_gem_extract_path(gem_name), env_vars, no_stdout: true)
  end
end

PackguySpec.define_docker_containers

Dir[File.expand_path('../support/**/*.rb', __FILE__)].each { |f| require f }
