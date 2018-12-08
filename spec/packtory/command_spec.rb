require_relative '../spec_helper'

describe 'Packtory CLI' do
  context 'passed with no options' do
    before do
      Packtory::Command.silent!
    end

    it 'should return a non-zero' do
      exit_number = Packtory::Command.run([ ])
      expect(exit_number).to eq(1)
    end
  end

  context 'parse common options' do
    before do
      @packtory = Packtory::Command.new
      expect(@packtory).to receive(:perform_build_command).once.and_return(nil)
    end

    it 'set output type properly' do
      exit_number = @packtory.run([ 'build', '-t', 'deb' ])
      expect(Packtory.config[:packages]).to include(:deb)
      expect(exit_number).to eq(0)
    end

    it 'set package path properly' do
      exit_number = @packtory.run([ 'build', '-p', 'some_pkg_path/' ])
      expect(Packtory.config[:pkg_path]).to eq(File.expand_path('some_pkg_path/'))
      expect(exit_number).to eq(0)
    end

    it 'set package name properly' do
      exit_number = @packtory.run([ 'build', '-n', 'somepkgname' ])
      expect(Packtory.config[:package_name]).to eq('somepkgname')
      expect(exit_number).to eq(0)
    end
  end

  context 'passed with build command' do
    before do
      @packtory = Packtory::Command.new
    end

    it 'should call build method' do
      expect(@packtory).to receive(:perform_build_command).once.and_return(nil)
      exit_number = @packtory.run([ 'build' ])
      expect(exit_number).to eq(0)
    end
  end
end
