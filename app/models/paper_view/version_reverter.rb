module PaperView
  class VersionReverter
    Result = Struct.new(:status, :message) do
      def success?
        status == :success
      end
    end

    def self.available_for?(version)
      return false unless PaperView.config.revert_enabled
      return PaperView.config.undo_create_enabled if version.event == "create"
      true
    end

    def initialize(version)
      @version = version
    end

    def call
      return failure("Reverting is disabled.") unless self.class.available_for?(@version)

      (@version.event == "create") ? undo_create : restore_previous_state
    rescue ActiveRecord::RecordInvalid => error
      failure("Could not revert: #{error.record.errors.full_messages.to_sentence}")
    rescue => error
      failure("Could not revert: #{error.class} – #{error.message}")
    end

    private

    def undo_create
      record = @version.item
      return failure("#{label} no longer exists.") if record.nil?

      record.destroy!
      success("Destroyed #{label} – the creation recorded in version ##{@version.id} was undone.")
    end

    def restore_previous_state
      reified = @version.reify(PaperView.config.reify_options)
      return failure("Version ##{@version.id} carries no previous state to restore.") if reified.nil?

      reified.save!
      success("Rolled #{label} back to the state before version ##{@version.id}.")
    end

    def label
      "#{@version.item_type} ##{@version.item_id}"
    end

    def success(message)
      Result.new(:success, message)
    end

    def failure(message)
      Result.new(:failure, message)
    end
  end
end
