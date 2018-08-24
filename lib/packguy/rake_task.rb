module Packguy
  class RakeTask < ::Rake::TaskLib
    def self.install_tasks
      new.define_tasks
    end

    def initialize(which = [ ])
      @which = which

      Packer.setup
      detect_environment
    end

    def detect_environment
      if defined?(::RSpec)
        unless @which.include?(:spec_with_package)
          @which << :spec_with_package
        end
      end

      packages = Packer.config[:packages]
      packages.each do |pack|
        unless @which.include?(PACKAGE_METHOD_MAP)
          @which << PACKAGE_METHOD_MAP[pack]
        end
      end

      unless packages.empty?
        @which << :build_package
      end

      @which
    end

    def define_tasks
      @which.each do |task_name|
        case task_name
        when :build_package
          desc 'Create all the packages'
          task :build_package do
            build_package
          end
        when :build_deb
          desc 'Create a debian package'
          task :build_deb do
            build_deb
          end
        when :build_rpm
          desc 'Create an RPM package'
          task :build_rpm do
            build_rpm
          end
        when :spec_with_package
          desc 'Run RSpec code examples with package files'
          task :spec_with_package do
            spec_with_package
          end
        when :bundle_standalone
          desc 'Execute bundle --standalone to download and install local copies of gems'
          task :bundle_standalone do
            bundle_standalone
          end
        else
          # do nothing
        end
      end

      self
    end

    def build_package
      packages = Packer.config[:packages]
      packages.each do |pack|
        build_method = PACKAGE_METHOD_MAP[pack]
        unless build_method.nil?
          send(build_method)
        end
      end
    end

    def build_deb
      puts 'Building DEB package file...'
      packager, pkg_path = Packer.build_deb
      puts 'Done creating DEB: %s' % pkg_path
    end

    def build_rpm
      puts 'Building RPM package file...'
      packager, pkg_path = Packer.build_rpm
      puts 'Done creating RPM: %s' % pkg_path
    end

    def spec_with_package
      prefix_path = Packer.config[:deb_prefix]

      packager = Packer.new
      sfiles_map = packager.prepare_files(prefix_path)

      ENV['PACKGUY_WORKING_PATH'] = packager.working_path
      Rake::Task['spec'].execute
    end

    def bundle_standalone
      RakeTools.bundle_standalone
    end
  end
end
