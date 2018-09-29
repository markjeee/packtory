module Packtory
  class Config
    DEFAULT_CONFIG = {
      :path => nil,
      :pkg_path => nil,
      :gemspec => nil,
      :gemfile => nil,
      :binstub => nil,
      :bin_path => nil,
      :install_as_subpath => false,
      :setup_reset_gem_paths => true,
      :packages => nil,
      :architecture => 'all',

      # maybe specified, if wanting to override as set in gemspec file
      :package_name => nil,
      :working_path => nil,

      :dependencies => { },
      :bundle_working_path => nil,

      :fpm_use_ruby_path => nil,
      :fpm_exec_path => nil,
      :fpm_exec_verbose => false,
      :fpm_exec_log => nil,

      :bundler_silent => false,
      :bundler_local => false,
      :bundler_include => false
    }

    DEFAULT_PACKAGES = [ :deb ]
    PACKTORY_PACKFILE = 'Packfile'

    def self.config
      if defined?(@@global_config)
        @@global_config
      else
        reset_config!
      end
    end

    def self.configure
      yield config
    end

    def self.reset_config!
      @@global_config = DEFAULT_CONFIG.merge({ })
    end

    def self.setup_defaults
      if ENV.include?('PACKTORY_PACKAGES') && !ENV['PACKTORY_PACKAGES'].empty?
        config[:packages] = ENV['PACKTORY_PACKAGES'].split(',').collect { |p| p.to_sym }
      elsif config[:packages].nil?
        config[:packages] = DEFAULT_PACKAGES
      end

      if ENV.include?('PACKTORY_BUNDLE_WORKING_PATH')
        config[:bundle_working_path] = File.expand_path(ENV['PACKTORY_BUNDLE_WORKING_PATH'])
      end

      unless config[:dependencies].include?('ruby')
        config[:dependencies]['ruby'] = nil
      end
    end

    def self.search_up(*names)
      previous = nil
      current  = File.expand_path(config[:path] || Dir.pwd).untaint
      found_path = nil

      until !File.directory?(current) || current == previous || !found_path.nil?
        names.each do |name|
          path = File.join(current, name)
          if File.exists?(path)
            found_path = path
            break
          end
        end

        if found_path.nil?
          previous = current
          current = File.expand_path("..", current)
        end
      end

      found_path
    end

    def self.load_packfile
      packfile_path = nil

      if ENV.include?('PACKTORY_PACKFILE')
        packfile_path = File.expand_path(ENV['PACKTORY_PACKFILE'])
      else
        packfile_path = search_up(PACKTORY_PACKFILE)
      end

      unless packfile_path.nil?
        load packfile_path
      end

      packfile_path
    end

    def self.load_patch
      PatchBundlerNoMetadataDeps.patch!
    end

    def self.setup
      load_patch
      load_packfile
      setup_defaults
    end
  end
end
