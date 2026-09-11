RSpec.describe PaperView::AttributeChange do
  def change(name, old_value, new_value)
    described_class.new(name, old_value, new_value)
  end

  describe ".display" do
    it "marks nil" do
      expect(described_class.display(nil)).to eq(PaperView::EMPTY)
    end

    it "keeps an empty string visible" do
      expect(described_class.display("")).to eq('""')
    end

    it "uses the configured time format" do
      expect(described_class.display(Time.zone.parse("2026-09-11 10:00:00"))).to eq("2026-09-11 10:00:00")
    end

    it "shows stored utc times in the application zone" do
      expect(described_class.display(Time.utc(2026, 9, 11, 8, 0, 0))).to eq("2026-09-11 10:00:00")
    end

    it "renders structures compactly by default" do
      expect(described_class.display({"a" => 1})).to eq('{"a":1}')
    end

    it "pretty prints structures on request" do
      expect(described_class.display({"a" => 1}, pretty: true)).to eq("{\n  \"a\": 1\n}")
    end

    it "falls back to inspect for values json cannot generate" do
      expect(described_class.display({"a" => Float::NAN})).to eq({"a" => Float::NAN}.inspect)
    end
  end

  describe "#leaves" do
    it "keeps the attribute name for a flat attribute" do
      leaves = change("name", "a", "b").leaves

      expect(leaves.map(&:path)).to eq(["name"])
      expect(leaves.map(&:old_text)).to eq(["a"])
    end

    it "keeps the full column name for a nested attribute" do
      leaves = change("payment_settings", {"iban" => "CH1"}, {"iban" => "CH2"}).leaves

      expect(leaves.map(&:path)).to eq(["payment_settings.iban"])
    end
  end

  describe "#key_changes" do
    subject(:attribute) { change("settings", {"a" => 1, "b" => {"c" => 2}}, {"a" => 1, "b" => {"c" => 3}}) }

    it "only covers changed keys" do
      expect(attribute.key_changes.map(&:path)).to eq(["b.c"])
    end

    it "counts the untouched keys" do
      expect(attribute.unchanged_key_count).to eq(1)
    end
  end
end
