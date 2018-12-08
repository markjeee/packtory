require 'bundler'

module Packtory
  autoload :VERSION, File.expand_path('../packtory/version', __FILE__)
  autoload :Command, File.expand_path('../packtory/command', __FILE__)

  autoload :Config, File.expand_path('../packtory/config', __FILE__)
  autoload :Constants, File.expand_path('../packtory/constants', __FILE__)

  autoload :PatchBundlerNoMetadataDeps, File.expand_path('../packtory/patch_bundler_no_metadata_deps', __FILE__)
  autoload :FpmExec, File.expand_path('../packtory/fpm_exec', __FILE__)
  autoload :Packer, File.expand_path('../packtory/packer', __FILE__)

  autoload :Packages, File.expand_path('../packtory/packages', __FILE__)
  autoload :DebPackage, File.expand_path('../packtory/deb_package', __FILE__)
  autoload :RpmPackage, File.expand_path('../packtory/rpm_package', __FILE__)
  autoload :TgzPackage, File.expand_path('../packtory/tgz_package', __FILE__)
  autoload :BrewPackage, File.expand_path('../packtory/brew_package', __FILE__)

  # TODO: Evaluate and refactor
  autoload :RakeTask, File.expand_path('../packtory/rake_task', __FILE__)

  def self.config
    Config.config
  end

  def self.setup
    Config.setup
  end

  def self.build_package
    Packages.build_package
  end

  def self.after_install_script_path
    File.expand_path('../../bin/support/after_install_script', __FILE__)
  end

  def self.gem_build_extensions_path
    File.expand_path('../../bin/support/gem_build_extensions', __FILE__)
  end

  def self.bin_support_fpm_path
    File.expand_path('../../bin/support/fpm', __FILE__)
  end

  def self.bundler_setup_path
    File.expand_path('../packtory/bundler/setup.rb', __FILE__)
  end
end
