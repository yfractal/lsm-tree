# frozen_string_literal: true

module LSM
  class Run
    attr_reader :entries

    def initialize(max_entries_count = 2)
      @max_entries_count = max_entries_count
      @entries = []
    end

    def <<(entry)
      raise "Run is full" if @entries.count >= @max_entries_count
      @entries << entry

      self
    end
  end
end
