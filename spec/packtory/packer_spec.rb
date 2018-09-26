require_relative '../spec_helper'

describe 'Packer' do
  context 'setup' do
    before do
      PacktorySpec.packtory_setup
      @packer = Packtory::Packer.new
    end

    it 'found a gemfile' do
      expect(@packer.gemfile).not_to be_nil
    end

    it 'found a gemspec_file' do
      expect(@packer.gemspec_file).not_to be_nil
    end

    it 'load gemspec' do
      expect(@packer.gemspec.name).to eq('some_gem')
    end

    it 'set default packages' do
      expect(@packer.opts[:packages]).to include(:deb)
    end

    it 'set ruby as a dependency' do
      expect(@packer.opts[:dependencies]).to include('ruby')
    end
  end

  context 'custom gemfile' do
    before do
      opts = {
        :gemfile => File.join(PacktorySpec::VALID_BUILD_PATH, 'custom_gemfile/Gemfile')
      }

      PacktorySpec.packtory_setup(opts)
      @packer = Packtory::Packer.new
    end

    it 'use custom gemspec' do
      expect(File.basename(@packer.gemspec_file)).to eq('custom1.gemspec')
    end

    it 'load custom gemspec' do
      expect(@packer.gemspec.name).to eq('custom1_gem')
    end
  end

  context 'custom gemspec' do
    before do
      opts = {
        :gemspec => File.join(PacktorySpec::VALID_BUILD_PATH, 'gemspecs/another.gemspec')
      }

      PacktorySpec.packtory_setup(opts)
      @packer = Packtory::Packer.new
    end

    it 'load custom gemspec file' do
      expect(@packer.gemspec.name).to eq('some_other_gem')
    end
  end

  context 'prepare' do
    before do
      PacktorySpec.packtory_setup
      @packer = Packtory::Packer.new
      @prefix_path = Packtory::DebPackage::INSTALL_PREFIX
    end

    it 'should gather files' do
      files = @packer.gather_files

      expect(files).to include('README.md')
      expect(files).to include('lib/some_gem.rb')
      expect(files).to include('bundle/bundler/setup.rb')
    end

    it 'should prepare files' do
      source_files_map = @packer.prepare_files(@prefix_path)

      expect(source_files_map).not_to be_nil
      expect(source_files_map).not_to be_empty
    end
  end

  context 'deb package' do
    before do
      skip 'Faulty, due to Bundler use when packing messes up the Bundler env of test runtime'

      PacktorySpec.packtory_setup
      @package, @pkg_file = Packtory::Packer.build_deb
    end

    it 'should build package' do
      expect(File.exists?(@pkg_file)).to be_truthy
    end
  end

  context 'rpm package' do
    before do
      skip 'Faulty, due to Bundler use when packing messes up the Bundler env of test runtime'

      PacktorySpec.packtory_setup
      @package, @pkg_file = Packtory::Packer.build_rpm
    end

    it 'should build package' do
      expect(File.exists?(@pkg_file)).to be_truthy
    end
  end
end
