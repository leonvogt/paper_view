RSpec.describe PaperView::ChangeSet do
  def change_set(object_changes)
    described_class.for(Version.new(object_changes: object_changes))
  end

  it "builds entries from a yaml payload" do
    set = change_set(YAML.dump({"name" => %w[a b], "count" => [1, 2]}))

    expect(set).not_to be_unreadable
    expect(set.size).to eq(2)
    expect(set.map(&:name)).to eq(%w[name count])
  end

  it "reads a payload paper_trail cannot deserialize" do
    set = change_set(YAML.dump({"published_at" => [nil, Time.zone.parse("2026-09-11 10:00:00")]}))

    expect(set).not_to be_unreadable
    expect(set.first.new_text).to eq("2026-09-11 10:00:00")
  end

  it "skips entries that are not old/new pairs" do
    set = change_set(YAML.dump({"name" => %w[a b], "weird" => "single", "three" => [1, 2, 3]}))

    expect(set.map(&:name)).to eq(%w[name])
  end

  it "is empty without a payload" do
    set = change_set(nil)

    expect(set).to be_empty
    expect(set).not_to be_unreadable
  end

  it "is unreadable when the payload cannot be parsed" do
    set = change_set("--- not: [a payload\n")

    expect(set).to be_unreadable
    expect(set).to be_empty
  end

  it "survives a version without an object_changes column" do
    set = described_class.for(Struct.new(:id).new(1))

    expect(set).to be_empty
    expect(set).not_to be_unreadable
  end

  describe "#raw_text" do
    it "shows the stored payload untouched" do
      payload = YAML.dump({"name" => %w[a b]})

      expect(change_set(payload).raw_text).to eq(payload)
    end

    it "pretty prints a json column" do
      expect(change_set({"name" => %w[a b]}).raw_text).to eq("{\n  \"name\": [\n    \"a\",\n    \"b\"\n  ]\n}")
    end
  end
end
