RSpec.describe PaperView::TextDiff do
  def lines(count, prefix = "line")
    Array.new(count) { |index| "#{prefix} #{index}" }.join("\n")
  end

  describe ".for" do
    it "ignores short values" do
      expect(described_class.for("a\nb", "a\nc")).to be_nil
    end

    it "ignores identical values" do
      expect(described_class.for(lines(10), lines(10))).to be_nil
    end

    it "ignores non strings" do
      expect(described_class.for(nil, lines(10))).to be_nil
    end
  end

  describe "#hunks" do
    subject(:diff) { described_class.for(old_text, new_text) }

    let(:old_text) { (0..19).map { |index| "line #{index}" }.join("\n") }
    let(:new_text) { old_text.sub("line 10", "line ten") }

    it "counts both sides" do
      expect(diff.added_count).to eq(1)
      expect(diff.removed_count).to eq(1)
      expect(diff.unchanged_count).to eq(19)
    end

    it "keeps only the changed region with its context" do
      expect(diff.hunks.size).to eq(1)
      expect(diff.hunks.first.lines.map(&:text)).to eq(
        ["line 7", "line 8", "line 9", "line 10", "line ten", "line 11", "line 12", "line 13"]
      )
    end

    it "numbers both sides" do
      changed = diff.hunks.first.lines.select { |line| !line.context? }

      expect(changed.map { |line| [line.kind, line.old_number, line.new_number] }).to eq(
        [[:deleted, 11, nil], [:added, nil, 11]]
      )
    end

    it "labels the range like a unified diff" do
      expect(diff.hunks.first.header).to eq("@@ -8,7 +8,7 @@")
    end

    it "splits distant edits into separate hunks" do
      diff = described_class.for(old_text, old_text.sub("line 1\n", "line one\n").sub("line 15", "line fifteen"))

      expect(diff.hunks.size).to eq(2)
    end

    it "merges edits that share their context" do
      diff = described_class.for(old_text, old_text.sub("line 10", "line ten").sub("line 12", "line twelve"))

      expect(diff.hunks.size).to eq(1)
    end
  end

  describe "insertions" do
    it "marks added lines only" do
      old_text = lines(8)
      new_text = old_text.sub("line 4", "line 4\nline 4a\nline 4b")
      diff = described_class.for(old_text, new_text)

      expect(diff.added_count).to eq(2)
      expect(diff.removed_count).to eq(0)
      expect(diff.hunks.first.lines.select { |line| line.kind == :added }.map(&:text)).to eq(["line 4a", "line 4b"])
    end

    it "handles a value that grew from nothing shared" do
      diff = described_class.for(lines(6, "old"), lines(6, "new"))

      expect(diff.removed_count).to eq(6)
      expect(diff.added_count).to eq(6)
      expect(diff.unchanged_count).to eq(0)
      expect(diff.hunks.size).to eq(1)
    end
  end

  describe "large values" do
    it "diffs a local edit inside a long text quickly" do
      old_text = lines(3_000)
      new_text = old_text.sub("line 1500", "line fifteen hundred")

      diff = described_class.for(old_text, new_text)

      expect(diff.hunks.size).to eq(1)
      expect(diff.added_count).to eq(1)
      expect(diff.unchanged_count).to eq(2_999)
    end

    it "keeps scattered edits apart instead of replacing the whole text" do
      old_text = lines(3_000)
      new_text = old_text.sub("line 100\n", "changed 100\n").sub("line 2900\n", "changed 2900\n")

      diff = described_class.for(old_text, new_text)

      expect(diff.hunks.size).to eq(2)
      expect(diff.added_count).to eq(2)
      expect(diff.removed_count).to eq(2)
    end

    it "falls back to a replaced block when the changed region is too big" do
      old_text = lines(1_200, "old")
      new_text = lines(1_200, "new")

      diff = described_class.for(old_text, new_text)

      expect(diff.removed_count).to eq(1_200)
      expect(diff.added_count).to eq(1_200)
    end
  end
end
