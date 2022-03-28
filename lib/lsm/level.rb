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
        str = "SSTable(on disk): entries count=#{sstable.entries.count}"
        str + " " * (40 - str.length)
      end

      i = 0
      while true
        has_entrie = false
        table[i+1] = []
        @sstables.each do |sstable|
          entry = sstable.entries[i]

          if entry != nil
            has_entrie = true
            str = "key=#{entry.key}, val=#{entry.val}"

            table[i+1] << str + " " * (40 - str.length)
          end
        end

        break if has_entrie == false
        i += 1
      end

      table.map{|row| row.join("  ") }.join("\n")
    end
  end
end
