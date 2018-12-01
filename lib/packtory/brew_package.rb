require 'bundler'
require 'digest'

module Packtory
  class BrewPackage
    INSTALL_PREFIX = '/usr/local/opt/%s'
    PACKAGE_PATH = '%s'

    def self.build_package(opts = { })
      packager = Packer.new({ :bin_path => 'bin',
                              :install_prefix_as_code => "File.expand_path('../../%s', File.realpath(__FILE__))"
                            }.merge(opts))

      sfiles_map = packager.prepare_files(INSTALL_PREFIX, PACKAGE_PATH)

      fpm_exec = FpmExec.new(packager)
      package_filename = '%s-%s.tar.gz' % [ packager.package_name, packager.version ]
      pkg_file_path = fpm_exec.build(sfiles_map, package_filename, type: :tgz)

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
