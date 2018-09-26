require_relative '../spec_helper'

describe 'Tgz Package' do
  context 'tgz package' do
    before do
      skip 'Faulty, due to Bundler use when packing messes up the Bundler env of test runtime'

      PacktorySpec.packtory_setup(:packages => [ :tgz ])
      @built = Packtory.build_package
    end

    it 'should build a package' do
      expect(@built.count).to eq(1)
    end

    it 'create a package file' do
      _, pkg_file = @built.first
      expect(File.exists?(pkg_file)).to be_truthy
    end
  end
end
