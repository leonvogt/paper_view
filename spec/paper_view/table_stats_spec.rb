RSpec.describe PaperView::TableStats do
  include_context "with a versions table"

  it "ranks the item types by estimated payload" do
    create_versions("Gadget", 10, 100)
    create_versions("Widget", 2, 4_000)

    stats = described_class.new

    expect(stats.rows.map(&:item_type)).to eq(%w[Widget Gadget])
    expect(stats.rows.map(&:estimated_bytes)).to eq([8_000, 1_000])
    expect(stats.estimated_total_bytes).to eq(9_000)
    expect(stats.total_count).to eq(12)
  end

  it "reports no disk size on an adapter that cannot tell" do
    expect(described_class.new.disk_size).to be_nil
  end

  it "is empty without versions" do
    expect(described_class.new).to be_empty
  end
end

RSpec.describe PaperView::TableStats::Row do
  it "scales the sampled average up to the whole item type" do
    row = described_class.new("Widget", 1_200, 512.0)

    expect(row.estimated_bytes).to eq(614_400)
    expect(row.share(1_228_800)).to eq(0.5)
  end

  it "reports no estimate when the payload cannot be measured" do
    row = described_class.new("Widget", 1_200, nil)

    expect(row.estimated_bytes).to be_nil
    expect(row.share(1_000)).to eq(0.0)
  end

  it "treats an empty table as no share" do
    expect(described_class.new("Widget", 0, 512.0).share(0)).to eq(0.0)
  end
end
