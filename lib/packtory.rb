require 'bundler'

module Packtory
  autoload :VERSION, File.expand_path('../packtory/version', __FILE__)
  autoload :Command, File.expand_path('../packtory/command', __FILE__)

  autoload :PatchBundlerNoMetadataDeps, File.expand_path('../packtory/patch_bundler_no_metadata_deps', __FILE__)
  autoload :DebPackage, File.expand_path('../packtory/deb_package', __FILE__)
  autoload :RpmPackage, File.expand_path('../packtory/rpm_package', __FILE__)
  autoload :FpmExec, File.expand_path('../packtory/fpm_exec', __FILE__)
  autoload :Packer, File.expand_path('../packtory/packer', __FILE__)

  # TODO: Evaluate and refactor
  autoload :RakeTask, File.expand_path('../packtory/rake_task', __FILE__)

  def self.gem_build_extensions_path
    File.expand_path('../../bin/support/gem_build_extensions', __FILE__)
  end
end
