# frozen_string_literal: true

module LSM
  class Level
    attr_accessor :sstables

    def initialize(fanout)
      @fanout = fanout
      @sstables = []
    end

    def insert_entries(entries)
      sstable = SSTable.new
      sstable.entries = entries
      sstable.save_to_file
      @sstables = [sstable] + @sstables
    end

    def insert_sstable(sstable)
      @sstables = [sstable] + @sstables
    end

    def get(key)
      @sstables.each do |sstable|
        entry = sstable.get(key)
        return entry if entry
      end

      nil
    end

    def empty
      @sstables.each &:empty
      @sstables = []
    end

    def full?
      @sstables.count == @fanout
    end

    def to_s
      table = []
      table[0] = @sstables.map do |sstable|
        sstable.read_all_to_entries
        str = "sstable: count=#{sstable.entries.count}"
        str + " " * (20 - str.length)
      end

      i = 1
      while true
        has_entrie = false
        table[i] = []
        @sstables.each do |sstable|
          entry = sstable.entries[i]

          if entry != nil
            has_entrie = true
            str = "key=#{entry.key}, val=#{entry.val}"

            table[i] << str + " " * (20 - str.length)
          else
            table[i] << ""
          end
        end

        break if has_entrie == false
        i += 1
      end

      table.map{|row| row.join("  ") }.join("\n")
    end
  end
end
