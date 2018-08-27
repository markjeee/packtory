require_relative '../spec_helper'

describe 'Packguy binary' do
  context 'passed with valid build path' do
    before do
      @build_path = PackguySpec::VALID_BUILD_PATH
    end

    it 'should pack' do
      success = PackguySpec.pack(@build_path,
                                 { 'TEST_NOBUILD' => 1 },
                                 no_stdout: false)
      expect(success).to eq(true)
    end

    it 'should pack with custom gemspec' do
      success = PackguySpec.pack(@build_path,
                                 { 'TEST_NOBUILD' => 1,
                                   'GEM_SPECFILE' => 'gemspecs/another.gemspec' },
                                 no_stdout: false)
      expect(success).to eq(true)
    end

    it 'should not pack with wrong gemspec' do
      success = PackguySpec.pack(@build_path,
                                 { 'TEST_NOBUILD' => 1,
                                   'GEM_SPECFILE' => 'gemspecs/donotexist.gemspec' },
                                 no_stdout: false)
      expect(success).to eq(false)
    end
  end

  context 'third-party gems' do
    before do
      unless ENV['INCLUDE_PACK_EXTRA_SPECS']
        skip 'Pack third party specs skipped, unless specified: env INCLUDE_PACK_EXTRA_SPECS=1'
      end

      PackguySpec::DownloadGems.check_and_download_gems_for_spec
    end

    PackguySpec.spec_gems.each do |gem_name, source_url|
      it 'should produce a package: %s' % gem_name do
        success = PackguySpec.pack_with_gems(gem_name)
        expect(success).to eq(true)
      end
    end
  end
end
