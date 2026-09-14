RSpec.describe PaperView::Metadata do
  def version(**attributes)
    MetaVersion.new(**attributes)
  end

  after { PaperView.config.metadata_columns = nil }

  it "picks up every column paper_trail did not write itself" do
    metadata = described_class.for(version(ip: "10.0.0.1", user_agent: "curl/8"))

    expect(metadata.map(&:name)).to eq(%w[ip user_agent])
    expect(metadata.map(&:text)).to eq(["10.0.0.1", "curl/8"])
  end

  it "keeps the first entries visible and the rest behind the disclosure" do
    metadata = described_class.for(version(ip: "10.0.0.1", user_agent: "curl/8", author_id: 12, note: "imported"))

    expect(metadata.visible.map(&:name)).to eq(%w[ip user_agent])
    expect(metadata.hidden.map(&:name)).to eq(%w[author_id note])
  end

  it "hides nothing when everything fits" do
    expect(described_class.for(version(ip: "10.0.0.1")).hidden).to be_empty
  end

  it "is empty when no metadata was stored" do
    expect(described_class.for(version).empty?).to be(true)
  end

  it "skips blank values but keeps false" do
    metadata = described_class.for(version(ip: "", note: nil, context: {}, flagged: false))

    expect(metadata.map(&:name)).to eq(["flagged"])
    expect(metadata.first.text).to eq("false")
  end

  it "formats structures and times like attribute values do" do
    metadata = described_class.for(version(context: {"source" => "api"},
      stamped_at: Time.zone.parse("2026-09-11 10:00:00")))

    expect(metadata.map(&:text)).to eq([%({"source":"api"}), "2026-09-11 10:00:00"])
  end

  it "honours an explicit column list" do
    PaperView.config.metadata_columns = ["note"]
    metadata = described_class.for(version(ip: "10.0.0.1", note: "imported"))

    expect(metadata.map(&:name)).to eq(["note"])
  end

  it "stays empty for a version class without columns" do
    plain = Version.new(object_changes: nil, id: 1, event: "update", item_type: "Widget", item_id: 7,
      created_at: Time.zone.now)

    expect(described_class.for(plain).empty?).to be(true)
  end
end
