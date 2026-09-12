class SqliteVersion < ActiveRecord::Base
  self.table_name = "versions"
end

RSpec.shared_context "with a versions table" do
  around do |example|
    configured = PaperView.config.version_class_name
    PaperView.config.version_class_name = "SqliteVersion"
    ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
    create_versions_table
    example.run
  ensure
    PaperView.config.version_class_name = configured
  end

  def create_versions_table(payload_columns: %i[object object_changes])
    ActiveRecord::Schema.verbose = false
    ActiveRecord::Schema.define do
      create_table :versions, force: true do |t|
        t.string :item_type
        payload_columns.each { |column| t.text column }
      end
    end

    SqliteVersion.reset_column_information
  end

  def create_versions(item_type, count, bytes)
    count.times { SqliteVersion.create!(item_type: item_type, object: "x" * bytes) }
  end
end
