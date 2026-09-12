RSpec.describe PaperView::PayloadSizes do
  include_context "with a versions table"

  subject(:payload_sizes) { described_class.new(PaperView::VersionsTable.new) }

  it "averages the payload bytes of each item type" do
    create_versions("Widget", 3, 400)
    create_versions("Gadget", 2, 100)

    expect(payload_sizes.average_bytes["Widget"]).to eq(400.0)
    expect(payload_sizes.average_bytes["Gadget"]).to eq(100.0)
  end

  it "measures every payload column in bytes, not characters" do
    SqliteVersion.create!(item_type: "Widget", object: "ü" * 100, object_changes: "x" * 50)

    expect(payload_sizes.average_bytes["Widget"]).to eq(250.0)
  end

  it "samples the newest versions, where the payloads are biggest" do
    stub_const("#{described_class}::SAMPLE_ROWS", 2)
    create_versions("Widget", 2, 100)
    create_versions("Widget", 2, 400)

    expect(payload_sizes.average_bytes["Widget"]).to eq(400.0)
  end

  it "falls back to the overall average for item types the sample missed" do
    stub_const("#{described_class}::SAMPLE_ROWS", 2)
    create_versions("Gadget", 2, 100)
    create_versions("Widget", 2, 400)

    expect(payload_sizes.average_bytes["Gadget"]).to eq(400.0)
  end

  it "estimates versions without an item type" do
    create_versions(nil, 2, 400)

    expect(payload_sizes.average_bytes[nil]).to eq(400.0)
  end

  it "has nothing to measure without payload columns" do
    create_versions_table(payload_columns: [])

    expect(payload_sizes).not_to be_measurable
    expect(payload_sizes.average_bytes).to eq({})
  end

  it "has nothing to measure when the sample query fails" do
    create_versions("Widget", 1, 400)
    allow(SqliteVersion.connection).to receive(:select_rows).and_raise(ActiveRecord::StatementInvalid)

    expect(payload_sizes).not_to be_measurable
  end

  it "has nothing to measure in an empty table" do
    expect(payload_sizes.average_bytes).to eq({})
  end
end
