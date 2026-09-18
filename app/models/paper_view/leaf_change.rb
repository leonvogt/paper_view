module PaperView
  class LeafChange
    attr_reader :path, :old_value, :new_value

    def initialize(path, old_value, new_value)
      @path = path.to_s
      @old_value = old_value
      @new_value = new_value
    end

    def under(prefix)
      self.class.new(prefixed(prefix), old_value, new_value)
    end

    def prefixed(prefix)
      return prefix if path.empty?

      path.start_with?("[") ? "#{prefix}#{path}" : "#{prefix}.#{path}"
    end

    def diff
      return @diff if defined?(@diff)

      @diff = TextDiff.for(old_value, new_value)
    end

    def old_text
      AttributeChange.display(old_value)
    end

    def new_text
      AttributeChange.display(new_value)
    end
  end
end
