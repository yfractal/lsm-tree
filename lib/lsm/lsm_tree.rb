# frozen_string_literal: true

module LSM
  class LSMTree
    attr_reader :mem_table, :levels

    def initialize(mem_table_max_entries=5, depth=5, fanout=5)
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
      table << ["LSMTree: mem_table_length=#{@mem_table_max_entries}, depth=#{@depth}, fanout=#{@fanout}"]

      table << mem_table.to_s + "\n"

      levels.each_with_index do |level, i|
        table << "Level: #{i}"
        table << level.to_s + "\n"
      end

      table.join("\n")
    end

    private
    def merge_down(from_level_index, to_level_index)
      from_level, to_level = levels[from_level_index], levels[to_level_index]

      merge_down(to_level_index, to_level_index + 1) if to_level.full?

      entries = merge_entries_list(from_level.sstables.map { |sstable| sstable.entries})

      to_level.insert_entries(entries)

      from_level.empty
    end

    def merge_entries_list(entries)
      return entries[0] if entries.count == 1

      queues = entries
      new_queues = []

      while queues.length > 0
        l1, l2 = queues.shift, queues.shift || []
        new_entries = merge_two_entries(l1, l2, [])
        new_queues << new_entries
      end

      merge_entries_list(new_queues)
    end

    def merge_two_entries(l1, l2, r)
      return r if l1 == nil || l2 == nil

      i, j = 0, 0
      while i < l1.length && j < l2.length
        if l1[i].key == l2[j].key
          r << l1[i]
          i += 1
          j += 1
        elsif l1[i].key < l2[j].key
          r << l1[i]
          i += 1
        else
          r << l2[j]
          j += 1
        end
      end

      while i < l1.length
        r << l1[i]
        i += 1
      end

      while j < l2.length
        r << l2[j]
        j += 1
      end

      r
    end
  end
end
