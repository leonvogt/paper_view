RSpec.describe PaperView::Payload do
  def parse(value)
    described_class.parse(value)
  end

  def dump(hash)
    parse(YAML.dump(hash))
  end

  it "returns a hash payload untouched" do
    hash = {"name" => ["a", "b"]}

    expect(parse(hash)).to be(hash)
  end

  it "parses json payloads" do
    expect(parse('{"name":["a","b"]}')).to eq({"name" => ["a", "b"]})
  end

  it "parses plain yaml payloads" do
    expect(dump({"name" => %w[a b], "count" => [1, 2]})).to eq({"name" => %w[a b], "count" => [1, 2]})
  end

  it "keeps quoted scalars as strings" do
    expect(dump({"zip" => %w[01234 0], "flag" => %w[true yes]})).to eq({"zip" => %w[01234 0], "flag" => %w[true yes]})
  end

  context "with ruby types active record refuses to load" do
    it "is the very case paper_trail cannot deserialize" do
      yaml = YAML.dump({"at" => [Time.utc(2026, 1, 1)]})

      expect { YAML.safe_load(yaml, permitted_classes: ActiveRecord.yaml_column_permitted_classes) }
        .to raise_error(Psych::DisallowedClass)
    end

    it "parses times" do
      expect(dump({"at" => [Time.utc(2026, 1, 1)]})).to eq({"at" => [Time.utc(2026, 1, 1)]})
    end

    it "parses symbols" do
      expect(dump({"state" => %i[draft live]})).to eq({"state" => %i[draft live]})
    end

    it "parses big decimals" do
      expect(dump({"price" => [BigDecimal("1.5")]})).to eq({"price" => [BigDecimal("1.5")]})
    end

    it "parses dates" do
      expect(dump({"due" => [Date.new(2026, 1, 1)]})).to eq({"due" => [Date.new(2026, 1, 1)]})
    end
  end

  it "keeps the recorded zone of a time with zone" do
    recorded = Time.zone.parse("2026-09-11 10:00:00")
    parsed = dump({"published_at" => [nil, recorded]})["published_at"].last

    expect(parsed).to eq(recorded)
    expect(parsed.time_zone.name).to eq("Europe/Zurich")
    expect(parsed.strftime("%Y-%m-%d %H:%M:%S")).to eq("2026-09-11 10:00:00")
  end

  it "degrades unknown class tags to their attributes" do
    yaml = "---\nfoo:\n- !ruby/object:Some::Missing::Class\n  bar: 1\n- \n"

    expect(parse(yaml)).to eq({"foo" => [{"bar" => 1}, nil]})
  end

  it "resolves aliases" do
    expect(parse("---\na:\n- &1\n  x: 1\n- *1\n")).to eq({"a" => [{"x" => 1}, {"x" => 1}]})
  end

  it "turns nested hash keys into strings" do
    expect(dump({"settings" => [{"a" => {"b" => 1}, :sym => true}]})).to eq({"settings" => [{"a" => {"b" => 1}, "sym" => true}]})
  end

  ["", nil, "   ", "not yaml: [", "--- just a string\n", "[1,2,3]", "--- \n- 1\n"].each do |value|
    it "returns nil for #{value.inspect}, which is not a mapping" do
      expect(parse(value)).to be_nil
    end
  end

  [
    "---\na:\n- 2026-13-45\n- x\n",
    "---\na:\n- 1e10000000\n- 2\n",
    "---\na:\n- !ruby/object:BigDecimal NOPE\n- 2\n",
    "---\na:\n- !binary |-\n  YWJj\n- 2\n"
  ].each do |yaml|
    it "never raises on the malformed scalar in #{yaml.lines[2].strip.inspect}" do
      expect(parse(yaml)).to be_a(Hash)
    end
  end
end
