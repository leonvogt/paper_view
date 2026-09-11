require "rails"
require "active_record"
require "active_support/all"

require "paper_view"

$LOAD_PATH.unshift File.expand_path("../app/models", __dir__)
require "paper_view/payload"
require "paper_view/leaf_change"
require "paper_view/attribute_change"
require "paper_view/change_set"
require "paper_view/version_row"

Time.zone = "Europe/Zurich"

Version = Struct.new(:object_changes, :id, :event, :item_type, :item_id, :created_at)

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed
end
