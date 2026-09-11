RSpec.describe PaperView do
  around do |example|
    original = described_class.config.version_class_name
    example.run
    described_class.config.version_class_name = original
  end

  describe ".version_class" do
    it "resolves the configured class" do
      described_class.config.version_class_name = "Version"
      expect(described_class.version_class).to eq(Version)
    end

    it "explains how to fix a missing class" do
      described_class.config.version_class_name = "PaperTrail::Version"
      expect { described_class.version_class }
        .to raise_error(PaperView::Error, /Add `gem "paper_trail"`/)
    end

    it "does not swallow unrelated NameErrors" do
      described_class.config.version_class_name = "BrokenVersion"
      stub_const("BrokenVersion", Class.new { def self.all = Missing })
      expect { described_class.version_class.all }.to raise_error(NameError, /Missing/)
    end
  end
end
