require 'yaml'
require 'optparse'

module Packtory
  class Command
    include Packtory::Constants
    attr_reader :options

    def self.silent!; @@silent = true; end
    def self.silent?; defined?(@@silent) ? @@silent : false; end

    def self.run(argv)
      self.new.run(argv)
    end

    def initialize
      @options = { }
      @completed = false
      @exit_number = 0
    end

    def detect_fpm(argv)
      if !ENV['FPM_EXEC_PATH'].nil? && !ENV['FPM_EXEC_PATH'].empty?
        fpm_exec_path = File.expand_path(ENV['FPM_EXEC_PATH'])
      else
        fpm_exec_path = Packtory.bin_support_fpm_path
      end

      Packtory.config[:fpm_exec_path] = fpm_exec_path

      if !ENV['FPM_USE_RUBY_PATH'].nil? && !ENV['FPM_USE_RUBY_PATH'].empty?
        Packtory.config[:fpm_use_ruby_path] = ENV['FPM_USE_RUBY_PATH']
      elsif !ENV['RUBY_PATH'].nil? && !ENV['RUBY_PATH'].empty?
        Packtory.config[:fpm_use_ruby_path] = ENV['RUBY_PATH']
      end

      if ENV['FPM_EXEC_VERBOSE'] && ENV['FPM_EXEC_VERBOSE'] == '1'
        Packtory.config[:fpm_exec_verbose] = true
      end

      if !ENV['FPM_EXEC_LOG'].nil? && !ENV['FPM_EXEC_LOG'].empty?
        Packtory.config[:fpm_exec_verbose] = true
        Packtory.config[:fpm_exec_log] = ENV['FPM_EXEC_LOG']
      end

      self
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

    def detect_package_opts(argv)
      packages = Packtory.config[:packages] || [ ]

      if ENV['PACKAGE_OUTPUT'] == 'rpm'
        packages << :rpm
      elsif ENV['PACKAGE_OUTPUT'] == 'deb'
        packages << :deb
      elsif ENV['PACKAGE_OUTPUT'] == 'tgz'
        packages << :tgz
      elsif ENV['PACKAGE_OUTPUT'] == 'brew'
        packages << :brew
      elsif packages.empty?
        packages << :deb
      end

      Packtory.config[:packages] = packages

      if ENV['PACKAGE_PATH'] && Packtory.config[:pkg_path].nil?
        Packtory.config[:pkg_path] = File.expand_path(ENV['PACKAGE_PATH'])
      end

      if !ENV['PACKAGE_NAME'].nil? && !ENV['PACKAGE_NAME'].empty?
        Packtory.config[:package_name] = ENV['PACKAGE_NAME']
      end

      if ENV['PACKAGE_DEPENDENCIES']
        deps = ENV['PACKAGE_DEPENDENCIES'].split(',')
        deps.each do |d|
          if d =~ /^([^\<\>\=]+)(.+)?$/
            pname = $~[1]
            pver = $~[2]

            Packtory.config[:dependencies][pname] = pver
          end
        end
      end

      self
    end

    def detect_ruby_opts(argv)
      ruby_ver = nil
      if ENV['PACKAGE_RUBY_VERSION'] && !ENV['PACKAGE_RUBY_VERSION'].empty?
        ruby_ver = ENV['PACKAGE_RUBY_VERSION']
      end

      Packtory.config[:dependencies]['ruby'] = ruby_ver
    end

    def options_parser
      OptionParser.new do |opts|
        opts.banner = 'Usage: %s [options]' % PACKTORY_BIN_NAME

        opts.on('-t TYPE', '--type=TYPE', 'Type of package to build (e.g. deb | rpm | brew)') do |t|
          Packtory.config[:packages] = [ t.to_sym ]
        end

        opts.on('-n PACKAGE_NAME', '--pkgname=PACKAGE_NAME', 'Override detected and set specific package name') do |n|
          Packtory.config[:package_name] = n
        end

        opts.on('-p PACKAGE_PATH', '--pkgpath=PACKAGE_PATH', 'Path where to create package') do |p|
          Packtory.config[:pkg_path] = File.expand_path(p)
        end

        opts.on('-v', 'Show version') do |v|
          options[:show_version] = true
        end
      end
    end

    def perform_options
      if options[:show_version]
        show_version
      end
    end

    def show_version
      say '%s' % Packtory::VERSION
      complete_and_exit!
    end

    def show_man
      man_path = File.expand_path('../../../man/packtory.1', __FILE__)
      Kernel.exec('man %s' % man_path)
    end

    def show_configs
      say 'Using fpm path   : %s' % Packtory.config[:fpm_exec_path]
      unless Packtory.config[:fpm_use_ruby_path].nil?
        say 'Fpm using ruby   : %s' % Packtory.config[:fpm_use_ruby_path]
      end
      say 'Using fpm        : %s' % `#{exec_fpm} -v`.strip

      say 'Package output   : %s' % Packtory.config[:packages].join(', ')

      unless Packtory.config[:pkg_path].nil?
        say 'Package path     : %s' % Packtory.config[:pkg_path]
      end

      unless Packtory.config[:package_name].nil?
        say 'Package name     : %s' % Packtory.config[:package_name]
      end

      if Packtory.config[:dependencies].include?('ruby')
        ruby_ver = Packtory.config[:dependencies]['ruby']
        if ruby_ver.nil?
          say 'Ruby deps        : latest'
        else
          say 'Ruby deps        : %s' % ruby_ver
        end
      end

      say '=================='
    end

    def exec_fpm
      if Packtory.config[:fpm_use_ruby_path].nil?
        Packtory.config[:fpm_exec_path]
      else
        'env FPM_USE_RUBY_PATH=%s %s' % [ Packtory.config[:fpm_use_ruby_path],
                                          Packtory.config[:fpm_exec_path] ]
      end
    end

    def test_dumpinfo(argv)
      info_h = {
        :version => ::Packtory::VERSION,
        :fpm_version => `#{exec_fpm} -v`.strip
      }.merge(Packtory.config)

      dump_file = ENV['TEST_DUMPINFO'] || '1'
      if dump_file == '1'
        f = StringIO.new
      else
        f = File.open(File.expand_path(dump_file), 'w+')
        say 'Created dump file: %s' % dump_file
      end

      f.write(YAML.dump(info_h))
      f.rewind
      say f.read
      f.close

      self
    end

    def perform_build_command(argv)
      detect_fpm(argv)
      detect_specfile(argv)
      detect_gemfile(argv)

      $:.unshift(@build_path)
      Dir.chdir(@build_path)

      Packtory.setup
      show_configs

      if ENV['TEST_DUMPINFO']
        test_dumpinfo(argv)
      elsif ENV['TEST_NOBUILD']
        complete_and_exit!
      else
        Packtory.build_package
      end
    end

    def detect_and_perform_command(argv)
      detect_package_opts(argv)
      detect_ruby_opts(argv)

      if argv[0] == 'build'
        perform_build_command(argv)
      elsif argv[0] == 'man'
        show_man
      elsif argv[0].nil? || argv[0] == ''
        say 'ERROR: Build path not specified, aborting.'
        complete_and_exit! 1
      else
        @build_path = File.expand_path(argv[0])
        unless File.exists?(@build_path)
          say 'ERROR: Build path %s do not exist, aborting.' % @build_path
          complete_and_exit! 1
        end

        Packtory.config[:path] = @build_path
        say 'Using build path : %s' % @build_path
        perform_build_command(argv)
      end
    end

    def run(argv)
      options_parser.parse!(argv)
      perform_options

      detect_and_perform_command(argv) unless completed?
      complete_and_exit! unless completed?

      @exit_number
    end

    def completed?; @completed; end

    def complete_and_exit!(e = 0)
      @completed = true
      @exit_number = e
    end

    def say(msg)
      unless self.class.silent?
        puts msg
      end
    end
  end
end
