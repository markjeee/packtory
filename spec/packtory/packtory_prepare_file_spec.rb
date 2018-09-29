require_relative '../spec_helper'

describe 'Packtory file preparation' do
  context 'prepare files' do
    before do
      PacktorySpec.packtory_setup
      @packtory = Packtory::Packer.new
      @prefix_path = Packtory::DebPackage::INSTALL_PREFIX
    end

    it 'should build source files' do
      files = @packtory.build_file_map(@prefix_path)

      wp = @packtory.package_working_path
      expect(files.keys).to include(File.join(wp, 'some_gem/'))
    end
  end

  context 'gather files' do
    before do
      PacktorySpec.packtory_setup
      @packtory = Packtory::Packer.new
      @prefix_path = Packtory::DebPackage::INSTALL_PREFIX
    end

    it 'should include gem build tool' do
      files = @packtory.gather_files

      expect(files).to include(Packtory.gem_build_extensions_path)
    end
  end
end
