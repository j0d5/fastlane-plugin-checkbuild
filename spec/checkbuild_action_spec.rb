describe Fastlane::Actions::CheckbuildAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The checkbuild plugin is working!")

      Fastlane::Actions::CheckbuildAction.run(nil)
    end
  end
end
