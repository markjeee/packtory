module Packtory
  class Command
    def self.run(argv)
      self.new.run(argv)
    end

    def detect_envs(argv)
      if ENV['FPM_EXEC_PATH']
        @fpm_exec_path = File.expand_path(ENV['FPM_EXEC_PATH'])
      else
        @fpm_exec_path = `which fpm`.strip
      end

      if @fpm_exec_path.nil? || @fpm_exec_path.empty?
        puts 'ERROR: `fpm` executable is not in path. Perhaps, install fpm first?'
        exit 1
      end

      if argv[0].nil? || argv[0].empty?
        puts 'ERROR: Build path not specified, aborting.'
        exit 1
      end

      @build_path = File.expand_path(argv[0])
      unless File.exists?(@build_path)
        puts 'ERROR: Build path %s do not exist, aborting.' % @build_path
        exit 1
      end

      say 'Using fpm path   : %s' % @fpm_exec_path
      say 'Using fpm        : %s' % `#{@fpm_exec_path} -v`.strip

      say 'Using build path : %s' % @build_path

      Packer.config[:fpm_exec_path] = @fpm_exec_path
      Packer.config[:path] = @build_path

      self
    end

    def detect_specfile(argv)
      if ENV['GEM_SPECFILE']
        @gemspec_file = ENV['GEM_SPECFILE']
        unless @gemspec_file =~ /^\/(.+)$/
          @gemspec_file = File.join(@build_path, @gemspec_file)
        end

        unless File.exists?(@gemspec_file)
          puts 'ERROR: Specified gemspec file %s not found, aborting.' % @gemspec_file
          exit 1
        end
      else
        paths = Dir.glob(File.join(@build_path, '/*.gemspec'))
        if paths.empty?
          puts 'ERROR: No gemspec file found, aborting.'
          exit 1
        elsif paths.count > 1
          puts 'ERROR: Multiple gemspec file found, aborting.'
          exit 1
        end

        @gemspec_file = paths[0]
      end

      say 'Using spec file  : %s' % @gemspec_file
      Packer.config[:gemspec] = @gemspec_file

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
          puts 'ERROR: Specified bundle gemfile %s not found, aborting.' % @bundle_gemfile
          exit 1
        end

        puts 'Using Gemfile    : %s' % @bundle_gemfile
        Packer.config[:gemfile] = @bundle_gemfile
      end

      self
    end

    def detect_deps(argv)
      @deps = { }

      if ENV['PACKAGE_RUBY_VERSION'] && !ENV['PACKAGE_RUBY_VERSION'].empty?
        @ruby_version = ENV['PACKAGE_RUBY_VERSION']
        puts 'Using ruby deps  : %s' % @ruby_version
      else
        @ruby_version = nil
        puts 'Using ruby deps  : latest'
      end

      Packer.config[:dependencies]['ruby'] = @ruby_version
      @deps['ruby'] = @ruby_version

      if ENV['PACKAGE_DEPENDENCIES']
        deps = ENV['PACKAGE_DEPENDENCIES'].split(',')
        deps.each do |d|
          if d =~ /^([^\<\>\=]+)(.+)?$/
            pname = $~[1]
            pver = $~[2]

            Packer.config[:dependencies][pname] = pver
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
      else
        # Debian is the default output
        packages << :deb
      end

      puts 'Package output   : %s' % packages.join(', ')
      Packer.config[:packages] = packages

      self
    end

    def run(argv)
      detect_envs(argv)

      $:.unshift(@build_path)
      Dir.chdir(@build_path)

      detect_specfile(argv)
      detect_gemfile(argv)
      detect_deps(argv)
      detect_package_output(argv)

      puts '=================='

      Packer.setup
      unless ENV['TEST_NOBUILD']
        Packer.build_package
      end
    end

    def say(msg)
      puts msg
    end
  end
end
