require 'bundler'

module Packguy
  autoload :VERSION, File.expand_path('../packguy/version', __FILE__)
  autoload :Command, File.expand_path('../packguy/command', __FILE__)

  autoload :PatchBundlerNoMetadataDeps, File.expand_path('../packguy/patch_bundler_no_metadata_deps', __FILE__)
  autoload :DebPackage, File.expand_path('../packguy/deb_package', __FILE__)
  autoload :RpmPackage, File.expand_path('../packguy/rpm_package', __FILE__)
  autoload :FpmExec, File.expand_path('../packguy/fpm_exec', __FILE__)
  autoload :Packer, File.expand_path('../packguy/packer', __FILE__)

  # TODO: Evaluate and refactor
  autoload :RakeTask, File.expand_path('../packguy/rake_task', __FILE__)

  def self.gem_build_extensions_path
    File.expand_path('../../bin/support/gem_build_extensions', __FILE__)
  end
end
