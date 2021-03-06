require 'bundler'
require 'digest'

module Packtory
  class RpmPackage
    INSTALL_PREFIX = '/usr/share/ruby/vendor_ruby/%s'

    def self.build_package(opts = { })
      packager = Packer.new(opts)

      # add rubygems dependency
      unless packager.opts[:dependencies].include?('rubygems')
        packager.opts[:dependencies]['rubygems'] = nil
      end

      fpm_exec = FpmExec.new(packager, INSTALL_PREFIX)

      sfiles_map = packager.prepare_files(INSTALL_PREFIX)
      package_filename = '%s_%s_%s.rpm' % [ packager.package_name, packager.version, packager.architecture ]
      pkg_file_path = fpm_exec.build(sfiles_map, package_filename, type: :rpm)

      if File.exist?(pkg_file_path)
        Bundler.ui.info 'Created package: %s (%s bytes)' % [ pkg_file_path, File.size(pkg_file_path) ]
        Bundler.ui.info 'SHA256 checksum: %s' % Digest::SHA256.file(pkg_file_path).hexdigest
      else
        Bundler.ui.error '[ERROR] Package not found: %s' % [ pkg_file_path ]
      end

      [ packager, pkg_file_path ]
    end
  end
end
