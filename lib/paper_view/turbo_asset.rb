require "digest"

module PaperView
  # A plain Rack endpoint to serve Turbo.js
  class TurboAsset
    PATH = File.expand_path("assets/turbo.js", __dir__).freeze
    SOURCE = File.read(PATH).freeze
    DIGEST = Digest::SHA256.hexdigest(SOURCE).first(12).freeze

    HEADERS = {
      "content-type" => "text/javascript; charset=utf-8",
      "cache-control" => "public, max-age=31536000, immutable",
      "content-length" => SOURCE.bytesize.to_s
    }.freeze

    def self.call(env)
      # Rack middleware such as ETag writes to the header hash, so it cannot be shared.
      [200, HEADERS.dup, (env["REQUEST_METHOD"] == "HEAD") ? [] : [SOURCE]]
    end
  end
end
