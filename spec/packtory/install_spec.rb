require_relative '../spec_helper'

describe 'Install of generated package' do
  context 'Packtory debian package' do
    before do
      unless ENV['INCLUDE_INSTALL_SPECS']
        skip 'Install specs skipped, unless specified: env INCLUDE_INSTALL_SPECS=1'
      end

      @package_file = PacktorySpec.packtory_pack
      @pkgout_file_path = '%s.test_out' % @package_file
    end

    it 'should install packtory' do
      skip 'for now' if PacktorySpec.skip_if_only_one

      FileUtils.rm_f(@pkgout_file_path) if File.exists?(@pkgout_file_path)
      container = DockerTask.containers['packtory-spec.xenial']

      container.shhh do
        container.pull
        container.runi(:exec => '"/build/spec/exec/install_packtory_deb %s"' % PacktorySpec.calculate_build_path(@package_file))
      end

      expect(File.exists?(@pkgout_file_path)).to be_truthy

      dump_info = YAML.load(File.read(@pkgout_file_path))
      expect(dump_info[:version]).to eq(Packtory::VERSION)
      expect(dump_info[:fpm_version]).to eq(PacktorySpec.expected_fpm_version)
    end
  end

  context 'Fpm debian package' do
    before do
      unless ENV['INCLUDE_INSTALL_SPECS']
        skip 'Install specs skipped, unless specified: env INCLUDE_INSTALL_SPECS=1'
      end

      @pkg_file_path = PacktorySpec::DownloadGems.find_or_compile_package('fpm')
      @pkgout_file_path = '%s.test_out' % @pkg_file_path
    end

    it 'should install in Xenial' do
      #skip 'for now' if PacktorySpec.skip_if_only_one

      FileUtils.rm_f(@pkgout_file_path) if File.exists?(@pkgout_file_path)
      container = DockerTask.containers['packtory-spec.xenial']

      container.shhh do
        container.pull
        container.runi(:exec => '"/build/spec/exec/install_fpm_deb %s"' % PacktorySpec.calculate_build_path(@pkg_file_path))
      end

      expect(File.exists?(@pkgout_file_path)).to be_truthy

      path, ver = File.read(@pkgout_file_path).split(/\n/, 3)
      expect(path).to eq('/usr/local/bin/fpm')
      expect(ver).to eq(PacktorySpec.expected_fpm_version)
    end

    it 'should install in Bionic' do
      skip 'for now' if PacktorySpec.skip_if_only_one

      FileUtils.rm_f(@pkgout_file_path) if File.exists?(@pkgout_file_path)
      container = DockerTask.containers['packtory-spec.bionic']

      container.shhh do
        container.pull
        container.runi(:exec => '"/build/spec/exec/install_fpm_deb %s"' % PacktorySpec.calculate_build_path(@pkg_file_path))
      end

      expect(File.exists?(@pkgout_file_path)).to be_truthy

      path, ver = File.read(@pkgout_file_path).split(/\n/, 3)
      expect(path).to eq('/usr/local/bin/fpm')
      expect(ver).to eq(PacktorySpec.expected_fpm_version)
    end

    it 'should install in Jessie' do
      skip 'for now' if PacktorySpec.skip_if_only_one

      FileUtils.rm_f(@pkgout_file_path) if File.exists?(@pkgout_file_path)
      container = DockerTask.containers['packtory-spec.jessie']

      container.shhh do
        container.pull
        container.runi(:exec => '"/build/spec/exec/install_fpm_deb %s"' % PacktorySpec.calculate_build_path(@pkg_file_path))
      end

      expect(File.exists?(@pkgout_file_path)).to be_truthy

      path, ver = File.read(@pkgout_file_path).split(/\n/, 3)
      expect(path).to eq('/usr/local/bin/fpm')
      expect(ver).to eq(PacktorySpec.expected_fpm_version)
    end

    it 'should install in Stretch' do
      skip 'for now' if PacktorySpec.skip_if_only_one

      FileUtils.rm_f(@pkgout_file_path) if File.exists?(@pkgout_file_path)
      container = DockerTask.containers['packtory-spec.stretch']

      container.shhh do
        container.pull
        container.runi(:exec => '"/build/spec/exec/install_fpm_deb %s"' % PacktorySpec.calculate_build_path(@pkg_file_path))
      end

      expect(File.exists?(@pkgout_file_path)).to be_truthy

      path, ver = File.read(@pkgout_file_path).split(/\n/, 3)
      expect(path).to eq('/usr/local/bin/fpm')
      expect(ver).to eq(PacktorySpec.expected_fpm_version)
    end
  end
end
