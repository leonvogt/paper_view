RSpec.describe PaperView::VersionRow do
  def row(object_changes, event: "update")
    version = Version.new(object_changes: object_changes, id: 1, event: event, item_type: "Widget", item_id: 7,
      created_at: Time.zone.parse("2026-09-11 10:00:00"))
    described_class.new(version)
  end

  it "caps the lines it shows and counts the rest" do
    changes = YAML.dump((1..5).to_h { |i| ["field_#{i}", [i, i + 1]] })

    expect(row(changes).lines.map(&:path)).to eq(%w[field_1 field_2 field_3])
    expect(row(changes).footnotes).to eq(["..."])
  end

  it "shows no diff for a destroy" do
    destroyed = row(YAML.dump({"name" => ["Widget", nil]}), event: "destroy")

    expect(destroyed.lines).to be_empty
    expect(destroyed.footnotes).to be_empty
    expect(destroyed.change_label).to eq("1 final value")
  end

  it "calls out an empty payload" do
    expect(row(nil).footnotes).to eq(["no attribute changes recorded"])
  end

  it "calls out an unreadable payload" do
    expect(row("--- broken: [\n").footnotes).to eq(["payload not deserializable"])
  end

  it "lists nested attributes leaf by leaf" do
    changes = YAML.dump({"settings" => [{"a" => 1, "b" => 2}, {"a" => 9, "b" => 2}]})

    expect(row(changes).lines.map(&:path)).to eq(["settings.a"])
  end

  it "diffs a structure stored as json text" do
    changes = YAML.dump({"settings" => ['{"escalation_is_active":"0","send_reminder_after":"0"}',
      '{"escalation_is_active":"1","send_reminder_after":"0"}']})
    line = row(changes).lines.first

    expect([line.path, line.old_text, line.new_text]).to eq(["settings.escalation_is_active", "0", "1"])
  end
end
