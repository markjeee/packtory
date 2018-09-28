require 'bundler'

module Packtory
  class RpmPackage
    INSTALL_PREFIX = '/usr/share/ruby/vendor_ruby/'

    def self.build_package(opts = { })
      packager = Packer.new(opts)
      fpm_exec = FpmExec.new(packager, INSTALL_PREFIX)

      sfiles_map = packager.prepare_files(INSTALL_PREFIX)
      package_filename = '%s_%s_%s.rpm' % [ packager.package_name, packager.version, packager.architecture ]
      pkg_file_path = fpm_exec.build(sfiles_map, package_filename, type: :rpm)

      if File.exist?(pkg_file_path)
        Bundler.ui.info 'Created package: %s (%s bytes)' % [ pkg_file_path, File.size(pkg_file_path) ]
      else
        Bundler.ui.error '[ERROR] Package not found: %s' % [ pkg_file_path ]
      end

      [ packager, pkg_file_path ]
    end
  end
end
