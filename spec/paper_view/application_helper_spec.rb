RSpec.describe PaperView::ApplicationHelper do
  let(:view) do
    Class.new do
      include ActionView::Helpers::NumberHelper
      include PaperView::ApplicationHelper
    end.new
  end

  around do |example|
    I18n.translate("number.human.format") # the Simple backend overwrites anything stored before it loads
    I18n.backend.store_translations(:en, number: {human: {format: {precision: 1}}, percentage: {format: {precision: 0, significant: true}}})
    example.run
  ensure
    I18n.backend.reload!
  end

  it "keeps sizes readable when the host app rounds numbers to one digit" do
    expect(view.paper_view_bytes(15_133_614_080)).to eq("14.1 GB")
    expect(view.paper_view_bytes(2_468_724_736)).to eq("2.3 GB")
  end

  it "keeps percentages readable too" do
    expect(view.paper_view_percentage(0.772)).to eq("77.2%")
    expect(view.paper_view_percentage(0.812)).to eq("81.2%")
  end

  it "shows a dash when there is nothing to measure" do
    expect(view.paper_view_bytes(nil)).to eq(PaperView::ApplicationHelper::EMPTY)
  end
end
