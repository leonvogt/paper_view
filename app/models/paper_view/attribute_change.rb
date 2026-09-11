require "json"

module PaperView
  class AttributeChange
    attr_reader :name, :old_value, :new_value

    def self.format(value)
      case value
      when nil then ""
      when String then value
      when Hash, Array then pretty_json(value)
      when Time then value.strftime("%Y-%m-%d %H:%M:%S.%6N %Z")
      else value.to_s
      end
    end

    def self.pretty_json(value)
      JSON.pretty_generate(value)
    rescue
      value.inspect
    end

    def initialize(name, old_value, new_value)
      @name = name.to_s
      @old_value = old_value
      @new_value = new_value
    end

    def status
      if old_value.nil? && !new_value.nil?
        :added
      elsif !old_value.nil? && new_value.nil?
        :removed
      else
        :changed
      end
    end

    def filtered?
      PaperView.filtered_attribute?(name)
    end

    def old_text
      @old_text ||= self.class.format(old_value)
    end

    def new_text
      @new_text ||= self.class.format(new_value)
    end

    def multiline?
      old_text.include?("\n") || new_text.include?("\n")
    end

    def rows
      @rows ||= LineDiff.new(old_text, new_text).rows
    end

    def paired_rows
      @paired_rows ||= LineDiff.pair(rows)
    end
  end
end
