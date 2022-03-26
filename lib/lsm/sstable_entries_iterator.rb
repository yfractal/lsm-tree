module LSM
  class SSTableEntriesIterator
    def initialize(sstable)
      @sstable = sstable
      @fence_index = 0
      @entries_index = 0
      @current_entries = @sstable.read_from_file(0)
    end

    def current_entry
      return nil if @current_entries[@entries_index] == nil
      key = @current_entries[@entries_index].to_i
      val = @current_entries[@entries_index + 1]

      Entry.new(key, val)
    end

    def next
      @entries_index += 2

      if @entries_index >= @current_entries.length
        @fence_index += 1

        if @fence_index < @sstable.fences.length
          @current_entries = @sstable.read_from_file(@fence_index)
          @entries_index = 0
        end
      end
    end
  end
end
