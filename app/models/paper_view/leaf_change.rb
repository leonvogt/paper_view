module PaperView
  class LeafChange
    attr_reader :path, :old_value, :new_value

    def initialize(path, old_value, new_value, nested: false)
      @path = path.to_s
      @old_value = old_value
      @new_value = new_value
      @nested = nested
    end

    def nested?
      @nested
    end

    def old_text
      AttributeChange.inline(old_value)
    end

    def new_text
      AttributeChange.inline(new_value)
    end

    def root
      path.split(".").first
    end

    def flat_path
      path.tr(".", "_")
    end

    def same_values?(other)
      old_value == other.old_value && new_value == other.new_value
    end
  end
end
