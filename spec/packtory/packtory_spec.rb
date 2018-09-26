require_relative '../spec_helper'

describe 'Packtory' do
  context 'build' do
    before do
      skip 'Faulty, due to Bundler use when packing messes up the Bundler env of test runtime'

      PacktorySpec.packtory_setup
      @build = Packtory.build_package
    end

    it 'build a package' do
      expect(@build.count).to be(1)
    end

    it 'created a package file' do
      _, pkg_file = @build.first
      expect(File.exists?(pkg_file)).to be_truthy
    end
  end
end
