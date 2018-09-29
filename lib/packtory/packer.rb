require 'fileutils'
require 'bundler'
require 'erb'

module Packtory
  class Packer
    BUNDLE_TARGET_PATH = 'bundle'
    BUNDLE_EXTENSIONS_PATH = 'extensions'
    BUNDLE_PACKTORY_TOOLS_PATH = 'packtory_tools'
    BUNDLE_BUNDLER_SETUP_FILE = 'bundler/setup.rb'

    DEFAULT_BIN_PATH = '/usr/local/bin'

    def self.silence_warnings
      original_verbosity = $VERBOSE
      $VERBOSE = nil
      ret = yield
      $VERBOSE = original_verbosity
      ret
    end

    attr_reader :opts
    attr_reader :gemfile
    attr_reader :gemspec_file

    def initialize(opts = { })
      @opts = Packtory.config.merge(opts)

      unless @opts[:gemfile].nil?
        @gemfile = Pathname.new(@opts[:gemfile])
      else
        @gemfile = nil
      end

      if @opts[:gemspec].nil?
        @gemspec_file = find_default_gemspec_file
      else
        @gemspec_file = @opts[:gemspec]
      end

      if @gemfile.nil?
        @gemfile = autogenerate_clean_gemfile
      end

      self
    end

    def find_default_gemspec_file
      files = [ ]
      try_paths = [ ]

      unless @gemfile.nil?
        try_paths << @gemfile.untaint.expand_path.parent.to_s
      end

      try_paths << root_path

      try_paths.detect do |tpath|
        files.concat(Dir.glob(File.join(tpath, '{,*}.gemspec')))
        files.count > 0
      end

      unless files.empty?
        File.expand_path(files.first)
      else
        nil
      end
    end

    def bundler_definition
      if defined?(@bundle_def)
        @bundle_def
      else
        ENV['BUNDLE_GEMFILE'] = @gemfile.to_s

        install_opts = { }
        install_opts[:with] = [ :default ]
        install_opts[:without] = [ :development, :test, :documentation ]
        install_opts[:path] = bundle_working_path
        install_opts[:retry] = 3
        install_opts[:jobs] = 3

        # in case, we are called multiple times
        Bundler.reset!

        if @opts[:bundler_silent]
          Bundler.ui = Bundler::UI::Silent.new
        else
          Bundler.ui = Bundler::UI::Shell.new
          Bundler.ui.info 'Bundling with: %s' % @gemfile.to_s
        end

        if @opts[:bundler_local]
          install_opts[:local] = true
        end

        self.class.silence_warnings do
          Bundler.settings.temporary(install_opts) do
            @bundle_def = ::Bundler.definition
            @bundle_def.validate_runtime!
          end

          Bundler.settings.temporary({ :no_install => true }.merge(install_opts)) do
            Bundler::Installer.install(Bundler.root, @bundle_def, install_opts)
          end
        end

        rubygems_dir = Bundler.rubygems.gem_dir
        FileUtils.mkpath(File.join(rubygems_dir, 'specifications'))

        cached_gems = { }
        @bundle_def.specs.each do |spec|
          next unless spec.source.is_a?(Bundler::Source::Rubygems)
          cached_gems[spec.name] = spec.source.send(:cached_gem, spec)
        end

        if detect_bundler_include
          bundler_source = Bundler::Source::Rubygems.new('remotes' => 'https://rubygems.org')

          @bundler_spec =
            Bundler::RemoteSpecification.new('bundler', Bundler::VERSION,
                                             Gem::Platform::RUBY, bundler_source.fetchers.first)

          @bundler_spec.remote = Bundler::Source::Rubygems::Remote.new(bundler_source.remotes.first)

          bundler_source.send(:fetch_gem, @bundler_spec)
          cached_gems['bundler'] = bundler_source.send(:cached_gem, @bundler_spec)
        end

        cached_gems.each do |gem_name, cached_gem|
          installer = Gem::Installer.at(cached_gem, :path => rubygems_dir)
          installer.extract_files
          installer.write_spec
        end

        @bundle_def
      end
    end

    def gemspec
      if defined?(@spec)
        @spec
      elsif !@gemspec_file.nil?
        @spec = Gem::Specification.load(@gemspec_file)
      else
        @spec = nil
      end
    end

    def autogenerate_clean_gemfile
      FileUtils.mkpath(working_path)

      gemfile_path = File.join(working_path, 'Gemfile')
      File.open(gemfile_path, 'w') do |f|
        gemfile_content = <<GEMFILE
source "http://rubygems.org"
gemspec :path => '%s', :name => '%s'
GEMFILE

        gemfile_content = gemfile_content % [ File.dirname(@gemspec_file),
                                              File.basename(@gemspec_file, '.gemspec') ]
        f.write(gemfile_content)
      end

      Pathname.new(gemfile_path)
    end

    def root_path
      if @opts[:path].nil?
        File.expand_path('./')
      else
        @opts[:path]
      end
    end

    def pkg_path
      if @opts[:pkg_path].nil?
        File.join(root_path, 'pkg')
      else
        @opts[:pkg_path]
      end
    end

    def working_path
      if @opts[:working_path].nil?
        File.join(root_path, 'tmp/packtory_wp')
      else
        @opts[:working_path]
      end
    end

    def bundle_working_path
      @opts[:bundle_working_path] || File.join(working_path, 'bundle')
    end

    def package_working_path
      File.join(working_path, 'package')
    end

    def package_name
      if @opts[:package_name].nil?
        gemspec.name
      else
        @opts[:package_name]
      end
    end

    def version
      gemspec.version
    end

    def description
      gemspec.description.strip
    end

    def homepage
      gemspec.homepage
    end

    def author
      gemspec.authors.join(', ')
    end

    def license
      gemspec.license
    end

    def maintainer
      case gemspec.email
      when Array
        gemspec.email.first
      when String
        gemspec.email
      else
        nil
      end
    end

    def architecture
      @opts[:architecture]
    end

    def detect_bundler_include
      if @opts[:bundler_include]
        true
      elsif !gemspec.dependencies.detect { |d| d.name == 'bundler' }.nil?
        true
      else
        false
      end
    end

    def bundle_gems
      bgems = { }

      specs = bundler_definition.specs_for([ :default ])
      specs.each do |spec|
        next if gemspec.nil? || spec.name == gemspec.name

        if spec.name == 'bundler'
          if detect_bundler_include
            spec = @bundler_spec
          else
            next
          end
        end

        orig_spec = spec
        if spec.is_a?(Bundler::EndpointSpecification)
          rs = spec.instance_variable_get(:@remote_specification)
          if rs
            spec = rs
          elsif spec._local_specification
            spec = spec._local_specification
          end
        end

        bhash = { }

        bhash[:orig_spec] = orig_spec
        bhash[:spec] = spec
        bhash[:gem_path] = spec.full_gem_path

        bhash[:files] = Dir.glob(File.join(spec.full_gem_path, '**/*')).inject([ ]) { |a, f|
          unless File.directory?(f)
            a << f.gsub('%s/' % spec.full_gem_path, '')
          end

          a
        }.uniq

        bhash[:require_paths] = spec.full_require_paths.collect { |path|
          path.include?(bhash[:gem_path]) ?
            path.gsub(bhash[:gem_path], '') : nil
        }.compact.uniq

        bgems[spec.name] = bhash
      end

      bgems
    end

    def add_ruby_build_dependencies!
      unless @opts[:dependencies].include?('ruby-dev')
        @opts[:dependencies]['ruby-dev'] = @opts[:dependencies]['ruby']
      end

      unless @opts[:dependencies].include?('ruby-build')
        @opts[:dependencies]['ruby-build'] = @opts[:dependencies]['ruby']
      end

      @opts[:dependencies]
    end

    def gather_files_for_package
      files = { }

      unless gemspec.nil?
        (gemspec.files - gemspec.test_files).each do |fname|
          next if File.directory?(fname)
          fname = fname.gsub('%s/' % gemspec.full_gem_path, '')
          files[fname] = fname
        end
      end

      include_packtory_tools = false

      bgems = bundle_gems
      bgems.each do |gem_name, bhash|
        bhash[:files].each do |file|
          src_full_path = File.join(bhash[:gem_path], file)
          files[src_full_path] = File.join(BUNDLE_TARGET_PATH, gem_name, file)
        end

        unless bhash[:spec].extensions.empty?
          add_ruby_build_dependencies!
          include_packtory_tools = true

          files[bhash[:orig_spec].loaded_from] = File.join(BUNDLE_EXTENSIONS_PATH, '%s.gemspec' % gem_name)
        end
      end

      if include_packtory_tools
        files = gather_packtory_tools_for_package(files)
      end

      files[Packtory.bundler_setup_path] = { :target_path => File.join(BUNDLE_TARGET_PATH, BUNDLE_BUNDLER_SETUP_FILE) }

      files
    end

    def gather_packtory_tools_for_package(files)
      target_tools_path = File.join(BUNDLE_PACKTORY_TOOLS_PATH)

      gem_build_extensions_path = Packtory.gem_build_extensions_path
      files[gem_build_extensions_path] = File.join(target_tools_path, File.basename(gem_build_extensions_path))

      after_install_script_path = Packtory.after_install_script_path
      files[after_install_script_path] = { :target_path => File.join(target_tools_path,
                                                                     File.basename(after_install_script_path)),
                                           :values => { 'pg_PACKAGE_PATH' => '$(dirname "$this_dir")' } }

      files
    end

    def for_each_bundle_gems(&block)
      bgems = bundle_gems
      bgems.each do |gem_name, bhash|
        src_paths = bhash[:require_paths]
        if src_paths.count > 0
          rpaths = src_paths.dup
        else
          rpaths = [ '/lib' ]
        end

        yield(gem_name, bhash, rpaths)
      end
    end

    def gather_files
      prefix_path = File.join(package_working_path, package_name)

      if File.exists?(prefix_path)
        FileUtils.rm_r(prefix_path)
      end

      FileUtils.mkpath(prefix_path)

      files = gather_files_for_package
      files.each do |fsrc, ftarget|
        tvalues = nil

        if fsrc =~ /^\//
          fsrc_path = fsrc
        else
          fsrc_path = File.join(root_path, fsrc)
        end

        case ftarget
        when String
          ftarget_path = File.join(prefix_path, ftarget)
        when Hash
          ftarget_path = File.join(prefix_path, ftarget[:target_path])
          tvalues = ftarget[:values]
        end

        FileUtils.mkpath(File.dirname(ftarget_path))
        FileUtils.cp_r(fsrc_path, ftarget_path)

        if ftarget.is_a?(Hash)
          tf = TemplateFile.new(self, ftarget_path, tvalues)
          tf.evaluate!
        end

        ftarget_path
      end

      files
    end

    class TemplateFile
      def initialize(packer, file_path, tvalues)
        @packer = packer
        @file_path = file_path
        @tvalues = tvalues
      end

      def evaluate!
        erb = ERB.new(File.read(@file_path), nil, nil, '@output_buffer')
        File.write(@file_path, erb.result(binding))

        @file_path
      end

      def packer; @packer; end

      def concat(str)
        @output_buffer << str
      end

      private

      def method_missing(k, *args)
        if @tvalues.nil?
          super
        elsif @tvalues.include?(k.to_s)
          @tvalues[k.to_s]
        elsif @tvalues.include?(k)
          @tvalues[k]
        else
          super
        end
      end
    end

    def create_binstub(binstub_fname, prefix_path)
      binstub_code = <<CODE
#!/usr/bin/ruby

require "%s"
load "%s"
CODE

      src_bin_path = File.join(package_working_path, 'bin', binstub_fname)
      FileUtils.mkpath(File.dirname(src_bin_path))

      if @opts[:install_as_subpath]
        target_path = File.join(prefix_path, package_name, package_name)
      else
        target_path = File.join(prefix_path, package_name)
      end

      bundler_setup_path = File.join(target_path, BUNDLE_TARGET_PATH, BUNDLE_BUNDLER_SETUP_FILE)

      bindir_name = gemspec.nil? ? 'bin' : gemspec.bindir
      actual_bin_path = File.join(target_path, bindir_name, binstub_fname)

      File.open(src_bin_path, 'w') { |f| f.write(binstub_code % [ bundler_setup_path, actual_bin_path ]) }
      FileUtils.chmod(0755, src_bin_path)

      src_bin_path
    end

    def build_file_map(prefix_path, package_path = nil)
      files = { }

      source_path = File.join(package_working_path, package_name, '/')
      target_path = File.join(package_path || prefix_path, package_name)
      files[source_path] = target_path

      files
    end

    def add_bin_files(files, prefix_path, package_path = nil)
      bin_path = @opts[:bin_path] || DEFAULT_BIN_PATH

      if @opts[:binstub].nil?
        unless gemspec.nil? || gemspec.executables.nil? || gemspec.executables.empty?
          @opts[:binstub] = { }

          gemspec.executables.each do |exec_fname|
            @opts[:binstub][exec_fname] = File.join(bin_path, exec_fname)
          end
        end
      end

      @opts[:binstub].each do |binstub_fname, binstub_file|
        src_binstub_file = create_binstub(binstub_fname, prefix_path)
        files[src_binstub_file] = binstub_file
      end unless @opts[:binstub].nil?

      files
    end

    def prepare_files(prefix_path, package_path = nil)
      gather_files

      files = build_file_map(prefix_path, package_path)
      files = add_bin_files(files, prefix_path, package_path)

      files
    end
  end
end
