require 'bundler'

module Packtory
  class FpmExec
    def self.fpm_exec_path
      if !Packtory.config[:fpm_exec_path].nil? && !Packtory.config[:fpm_exec_path].empty?
        Packtory.config[:fpm_exec_path]
      else
        Packtory.bin_support_fpm_path
      end
    end

    def initialize(packager, prefix_path = nil)
      @packager = packager
      @prefix_path = prefix_path
    end

    def build(sfiles_map, package_file, opts = { })
      pkg_file = File.join(@packager.pkg_path, package_file)
      FileUtils.mkpath(File.dirname(pkg_file))

      cmd = build_cmd(sfiles_map, pkg_file, opts)

      Bundler.ui.info 'CMD: %s' % cmd

      unless Packtory.config[:fpm_exec_verbose]
        cmd = '%s >/dev/null 2>&1' % cmd
      end

      Bundler.clean_system(cmd)

      pkg_file
    end

    def build_cmd(sfiles_map, pkg_file, opts = { })
      cmd = '%s --log %s -f -s dir' % [ self.class.fpm_exec_path, Packtory.config[:fpm_exec_log] || 'warn' ]

      unless Packtory.config[:fpm_use_ruby_path].nil?
        cmd = 'env FPM_USE_RUBY_PATH=%s %s' % [ Packtory.config[:fpm_use_ruby_path], cmd ]
      end

      case opts[:type]
      when :rpm
        cmd << ' -t rpm --rpm-os linux'
      when :deb
        cmd << ' -t deb'
      when :tgz
        cmd << ' -t tar'
      else
        raise 'Unsupported type: %s' % opts[:type]
      end

      cmd << ' -a %s -m "%s" -n %s -v %s --description "%s" --url "%s" --license "%s" --vendor "%s"' %
             [ @packager.architecture,
               @packager.maintainer,
               @packager.package_name,
               @packager.version,
               @packager.description,
               @packager.homepage,
               @packager.license,
               @packager.author ]

      cmd << ' -p %s --after-install %s --template-scripts %s %s %s' %
             [ pkg_file,
               Packtory.after_install_script_path,
               package_dependencies,
               template_values,
               source_files_map(sfiles_map) ]

      cmd
    end

    def source_files_map(files)
      files.inject([ ]) do |a, (k,v)|
        a << '%s=%s' % [ k, v ]; a
      end.join(' ')
    end

    def template_values
      values = { }.merge(@packager.template_scripts_values)

      if !@prefix_path.nil?
        values['pg_PACKAGE_PATH'] = @prefix_path % @packager.package_name
      else
        values['pg_PACKAGE_PATH'] = '<'
      end

      values.collect do |k, v|
        '--template-value %s="%s"' % [ k, v ]
      end.join(' ')
    end

    def package_dependencies
      @packager.opts[:dependencies].collect do |k, v|
        if v.nil?
          '-d %s' % k
        else
          '-d "%s%s"' % [ k, v ]
        end
      end.join(' ')
    end
  end
end
