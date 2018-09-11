require_relative '../spec_helper'

describe 'Packtory fpm exec' do
  context 'build' do
    before do
      PacktorySpec.packtory_setup
      @packtory = Packtory::Packer.new

      prefix_path = Packtory::DebPackage::INSTALL_PREFIX
      @sfiles_map = @packtory.prepare_files(prefix_path)

      @fpm_exec = Packtory::FpmExec.new(@packtory, prefix_path)
    end

    it 'should perform debian build' do
      skip 'Faulty, due to Bundler use when packing messes up the Bundler env of test runtime'

      package_filename = '%s_%s_%s.deb' % [ @packtory.package_name, @packtory.version, @packtory.architecture ]
      pkg_file_path = @fpm_exec.build(@sfiles_map, package_filename, type: :deb)

      expect(File.exists?(pkg_file_path)).to be_truthy
    end

    it 'should build cmd for debian' do
      package_filename = '%s_%s_%s.deb' % [ @packtory.package_name, @packtory.version, @packtory.architecture ]
      pkg_file = File.join(@packtory.pkg_path, package_filename)

      cmd = @fpm_exec.build_cmd(@sfiles_map, pkg_file, type: :deb)
      expect(cmd).to include('-t deb')
    end

    it 'should perform rpm build' do
      skip 'Faulty, due to Bundler use when packing messes up the Bundler env of test runtime'

      package_filename = '%s_%s_%s.rpm' % [ @packtory.package_name, @packtory.version, @packtory.architecture ]
      pkg_file_path = @fpm_exec.build(@sfiles_map, package_filename, type: :rpm)

      expect(File.exists?(pkg_file_path)).to be_truthy
    end

    it 'should build cmd for rpm' do
      package_filename = '%s_%s_%s.rpm' % [ @packtory.package_name, @packtory.version, @packtory.architecture ]
      pkg_file = File.join(@packtory.pkg_path, package_filename)

      cmd = @fpm_exec.build_cmd(@sfiles_map, pkg_file, type: :rpm)
      expect(cmd).to include('-t rpm')
    end

    it 'should specify dependencies' do
      deps = @fpm_exec.package_dependencies
      expect(deps).to include('-d ruby')
    end

    it 'should build a files map' do
      map = @fpm_exec.source_files_map(@sfiles_map)
      expect(map).not_to be_empty
    end
  end
end
