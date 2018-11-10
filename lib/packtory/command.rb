require 'yaml'

module Packtory
  class Command
    def self.run(argv)
      self.new.run(argv)
    end

    def detect_envs(argv)
      if ENV['FPM_EXEC_PATH']
        @fpm_exec_path = File.expand_path(ENV['FPM_EXEC_PATH'])
      else
        @fpm_exec_path = Packtory.bin_support_fpm_path
      end

      if !ENV['FPM_USE_RUBY_PATH'].nil? && !ENV['FPM_USE_RUBY_PATH'].empty?
        Packtory.config[:fpm_use_ruby_path] = ENV['FPM_USE_RUBY_PATH']
      elsif !ENV['RUBY_PATH'].nil? && !ENV['RUBY_PATH'].empty?
        Packtory.config[:fpm_use_ruby_path] = ENV['RUBY_PATH']
      end

      if @fpm_exec_path.nil? || @fpm_exec_path.empty?
        say 'ERROR: `fpm` executable is not in path. Perhaps, install fpm first?'
        exit 1
      end

      if argv[0].nil? || argv[0].empty?
        say 'ERROR: Build path not specified, aborting.'
        exit 1
      end

      @build_path = File.expand_path(argv[0])
      unless File.exists?(@build_path)
        say 'ERROR: Build path %s do not exist, aborting.' % @build_path
        exit 1
      end

      say 'Using fpm path   : %s' % @fpm_exec_path
      unless Packtory.config[:fpm_use_ruby_path].nil?
        say 'Fpm using ruby   : %s' % Packtory.config[:fpm_use_ruby_path]
      end

      say 'Using fpm        : %s' % `#{exec_fpm} -v`.strip
      say 'Using build path : %s' % @build_path

      Packtory.config[:fpm_exec_path] = @fpm_exec_path
      Packtory.config[:path] = @build_path

      if ENV['FPM_EXEC_VERBOSE'] && ENV['FPM_EXEC_VERBOSE'] == '1'
        Packtory.config[:fpm_exec_verbose] = true
      end

      if !ENV['FPM_EXEC_LOG'].nil? && !ENV['FPM_EXEC_LOG'].empty?
        Packtory.config[:fpm_exec_verbose] = true
        Packtory.config[:fpm_exec_log] = ENV['FPM_EXEC_LOG']
      end

      self
    end

    def exec_fpm
      if Packtory.config[:fpm_use_ruby_path].nil?
        @fpm_exec_path
      else
        'env FPM_USE_RUBY_PATH=%s %s' % [ Packtory.config[:fpm_use_ruby_path], @fpm_exec_path ]
      end
    end

    def detect_specfile(argv)
      if ENV['GEM_SPECFILE']
        @gemspec_file = ENV['GEM_SPECFILE']
        unless @gemspec_file =~ /^\/(.+)$/
          @gemspec_file = File.join(@build_path, @gemspec_file)
        end

        unless File.exists?(@gemspec_file)
          say 'ERROR: Specified gemspec file %s not found, aborting.' % @gemspec_file
          exit 1
        end
      else
        paths = Dir.glob(File.join(@build_path, '/*.gemspec'))
        if paths.empty?
          say 'ERROR: No gemspec file found, aborting.'
          exit 1
        elsif paths.count > 1
          say 'ERROR: Multiple gemspec file found, aborting.'
          exit 1
        end

        @gemspec_file = paths[0]
      end

      say 'Using spec file  : %s' % @gemspec_file
      Packtory.config[:gemspec] = @gemspec_file

      self
    end

    def detect_gemfile(argv)
      @bundle_gemfile = nil

      if ENV['BUNDLE_GEMFILE'] && !ENV['BUNDLE_GEMFILE'].empty?
        @bundle_gemfile = ENV['BUNDLE_GEMFILE']

        unless @bundle_gemfile =~ /^\/(.+)$/
          @bundle_gemfile = File.join(@build_path, @bundle_gemfile)
        end

        unless File.exists?(@bundle_gemfile)
          say 'ERROR: Specified bundle gemfile %s not found, aborting.' % @bundle_gemfile
          exit 1
        end

        say 'Using Gemfile    : %s' % @bundle_gemfile
        Packtory.config[:gemfile] = @bundle_gemfile
      end

      if ENV['BUNDLER_INCLUDE']
        Packtory.config[:bundler_include] = true
      end

      self
    end

    def detect_deps(argv)
      @deps = { }

      if ENV['PACKAGE_RUBY_VERSION'] && !ENV['PACKAGE_RUBY_VERSION'].empty?
        @ruby_version = ENV['PACKAGE_RUBY_VERSION']
        say 'Using ruby deps  : %s' % @ruby_version
      else
        @ruby_version = nil
        say 'Using ruby deps  : latest'
      end

      Packtory.config[:dependencies]['ruby'] = @ruby_version
      @deps['ruby'] = @ruby_version

      if ENV['PACKAGE_DEPENDENCIES']
        deps = ENV['PACKAGE_DEPENDENCIES'].split(',')
        deps.each do |d|
          if d =~ /^([^\<\>\=]+)(.+)?$/
            pname = $~[1]
            pver = $~[2]

            Packtory.config[:dependencies][pname] = pver
            @deps[pname] = pver
          end
        end
      end

      self
    end

    def detect_package_output(argv)
      packages = [ ]

      if ENV['PACKAGE_OUTPUT'] == 'rpm'
        packages << :rpm
      elsif ENV['PACKAGE_OUTPUT'] == 'deb'
        packages << :deb
      elsif ENV['PACKAGE_OUTPUT'] == 'tgz'
        packages << :tgz
      elsif ENV['PACKAGE_OUTPUT'] == 'brew'
        packages << :brew
      else
        packages << :deb
      end

      say 'Package output   : %s' % packages.join(', ')
      Packtory.config[:packages] = packages

      if ENV['PACKAGE_PATH']
        pkg_path = File.expand_path(ENV['PACKAGE_PATH'])

        say 'Package path     : %s' % pkg_path
        Packtory.config[:pkg_path] = pkg_path
      end

      self
    end

    def detect_package_opts(argv)
      if !ENV['PACKAGE_NAME'].nil? && !ENV['PACKAGE_NAME'].empty?
        package_name = ENV['PACKAGE_NAME']

        say 'Package name     : %s' % package_name
        Packtory.config[:package_name] = package_name
      end

      self
    end

    def test_dumpinfo(argv)
      dump_file = File.expand_path(ENV['TEST_DUMPINFO'])

      info_h = {
        :version => ::Packtory::VERSION,
        :fpm_version => `#{@fpm_exec_path} -v`.strip
      }.merge(Packtory.config)

      File.open(dump_file, 'w') do |f|
        f.write(YAML.dump(info_h))
      end

      say 'Created dump file: %s' % dump_file
      say File.read(dump_file)

      self
    end

    def run(argv)
      detect_envs(argv)

      $:.unshift(@build_path)
      Dir.chdir(@build_path)

      detect_specfile(argv)
      detect_gemfile(argv)
      detect_deps(argv)
      detect_package_opts(argv)
      detect_package_output(argv)

      say '=================='

      Packtory.setup

      if ENV['TEST_DUMPINFO']
        test_dumpinfo(argv)
      elsif ENV['TEST_NOBUILD']
        # do nothing
      else
        Packtory.build_package
      end
    end

    def say(msg)
      puts msg
    end
  end
end
