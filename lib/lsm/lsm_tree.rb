# frozen_string_literal: true

module LSM
  class LSMTree
    attr_reader :mem_table, :levels, :mem_table_max_entries, :depth, :fanout

    def initialize(mem_table_max_entries = 5, depth = 5, fanout = 2)
      @mem_table_max_entries = mem_table_max_entries
      @depth = depth
      @fanout = fanout

      @mem_table = MemTable.new(@mem_table_max_entries)

      @levels = []
      @depth.times do
        @levels << Level.new(fanout)
      end
    end

    def get(key)
      entry = @mem_table.get(key)
      return entry if entry

      levels.each do |level|
        entry = level.get(key)
        return entry if entry
      end

      nil
    end

    def put(key, val)
      return true if @mem_table.put(key, val)

      level0 = @levels[0]

      merge_down(0, 1) if level0.full?

      level0.insert_entries(@mem_table.entries)

      @mem_table.empty
      @mem_table.put(key, val)
    end

    def to_s
      table = []

      table << mem_table.to_s

      levels.each_with_index do |level, i|
        next if level.sstables.length == 0

        table << "Level-#{i}:"
        table << level.to_s
      end

      table.join("\n")
    end

    private

    def merge_down(from_level_index, to_level_index)
      from_level = levels[from_level_index]
      to_level = levels[to_level_index]

      merge_down(to_level_index, to_level_index + 1) if to_level.full?

      entries = merge_sstables(from_level)

      to_level.insert_entries(entries)

      from_level.empty
    end

    def merge_sstables(level)
      queue = level.sstables.map { |sstable| LSM::SSTableEntriesIterator.new(sstable) }
      entries = []

      queue, entries = merge_sstables_helper(queue, entries) while queue.length > 0

      entries
    end

    def merge_sstables_helper(queue, entries)
      return queue, entries if queue.empty?

      if queue.length == 1
        while current = queue[0].current_entry
          entries << current
          queue[0].next
        end

        return [], entries
      end

      min = nil
      i = 0
      while i < queue.length
        if queue[i].current_entry.nil?
          i += 1
          next
        elsif min.nil?
          min = queue[i]
        elsif min.current_entry.key == queue[i].current_entry.key
          queue[i].next
        elsif min.current_entry.key > queue[i].current_entry.key
          min = queue[i]
        end
        i += 1
      end

      entries << min.current_entry
      min.next

      [queue.filter { |iterator| iterator.current_entry }, entries]
    end
  end
end
