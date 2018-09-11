require_relative '../spec_helper'

describe 'Packtory bundle_gems' do
  context 'perform bundle_gems' do
    before do
      PacktorySpec.packtory_setup
      @packtory = Packtory::Packer.new
      @prefix_path = @packtory.opts[:deb_prefix]
    end

    it 'should gather gems' do
      bgems = @packtory.bundle_gems

      expect(bgems).to include('highline')
      expect(bgems['highline'][:spec].name).to eq('highline')
    end

    it 'should identify files' do
      bgems = @packtory.bundle_gems

      highline = bgems['highline']
      expect(highline[:files]).not_to be_empty
      expect(highline[:files]).to include('lib/highline.rb')
    end

    it 'should add gem building tools' do
      @packtory.bundle_gems
    end
  end
end
