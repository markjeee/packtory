require_relative '../spec_helper'

describe 'Install of generated package' do
  context 'Fpm debian package' do
    before do
      unless ENV['INCLUDE_INSTALL_SPECS']
        skip 'Install specs skipped, unless specified: env INCLUDE_INSTALL_SPECS=1'
      end

      @pkg_file_path = PacktorySpec::DownloadGems.find_or_compile_package('fpm')
      @pkgout_file_path = '%s.test_out' % @pkg_file_path
    end

    it 'should install in Xenial' do
      FileUtils.rm_f(@pkgout_file_path) if File.exists?(@pkgout_file_path)
      container = DockerTask.containers['packtory-spec.xenial']

      container.shhh do
        container.pull
        container.runi(:exec => '"/build/spec/exec/install_fpm_deb %s"' % PacktorySpec.calculate_build_path(@pkg_file_path))
      end

      expect(File.exists?(@pkgout_file_path)).to be_truthy

      path, ver = File.read(@pkgout_file_path).split(/\n/, 3)
      expect(path).to eq('/usr/local/bin/fpm')
    end

    it 'should install in Bionic' do
      FileUtils.rm_f(@pkgout_file_path) if File.exists?(@pkgout_file_path)
      container = DockerTask.containers['packtory-spec.bionic']

      container.shhh do
        container.pull
        container.runi(:exec => '"/build/spec/exec/install_fpm_deb %s"' % PacktorySpec.calculate_build_path(@pkg_file_path))
      end

      expect(File.exists?(@pkgout_file_path)).to be_truthy

      path, ver = File.read(@pkgout_file_path).split(/\n/, 3)
      expect(path).to eq('/usr/local/bin/fpm')
    end

    it 'should install in Jessie' do
      FileUtils.rm_f(@pkgout_file_path) if File.exists?(@pkgout_file_path)
      container = DockerTask.containers['packtory-spec.jessie']

      container.shhh do
        container.pull
        container.runi(:exec => '"/build/spec/exec/install_fpm_deb %s"' % PacktorySpec.calculate_build_path(@pkg_file_path))
      end

      expect(File.exists?(@pkgout_file_path)).to be_truthy

      path, ver = File.read(@pkgout_file_path).split(/\n/, 3)
      expect(path).to eq('/usr/local/bin/fpm')
    end

    it 'should install in Stretch' do
      FileUtils.rm_f(@pkgout_file_path) if File.exists?(@pkgout_file_path)
      container = DockerTask.containers['packtory-spec.stretch']

      container.shhh do
        container.pull
        container.runi(:exec => '"/build/spec/exec/install_fpm_deb %s"' % PacktorySpec.calculate_build_path(@pkg_file_path))
      end

      expect(File.exists?(@pkgout_file_path)).to be_truthy

      path, ver = File.read(@pkgout_file_path).split(/\n/, 3)
      expect(path).to eq('/usr/local/bin/fpm')
    end
  end
end
