# frozen_string_literal: true

module LSM
  class SSTable
    attr_reader :file_name, :fences
    attr_accessor :entries

    def initialize
      @entries = []
      @fences = []
      @pagesize = Helper.system_pagesize
      @file_name = Helper.mktemp("/tmp/lsm-XXXXXX")
      @bloom_filter = BloomFilter.new(10000)
    end

    def get(key)
      return nil if !@bloom_filter.has?(key)

      fence_index = find(fences, :itself, key)
      fence_index = [fence_index, fences.length - 1].min

      find_in_file(key, fence_index)
    end

    def save_to_file
      write_entries_to_file(@entries)
    end

    # for presenting
    def read_all_to_entries
      raw = File.open(@file_name).read.gsub("*", "").split(/\n|,/)

      i = 0
      @entries = []

      while i < raw.length
        @entries << Entry.new(raw[i], raw[i+1])
        i += 2
      end

      @entries
    end

    def empty
      File.delete(@file_name)
    end

    def read_from_file(offset)
      IO.read(@file_name, @pagesize, offset * @pagesize).gsub("*", "").split(/\n|,| /)
    end

    private
    def find_in_file(target_key, offset)
      entries = read_from_file(offset)

      i = 0
      while i < entries.length
        # NOTICE: suppose all key is integer
        key = entries[i].to_i
        return Entry.new(key, entries[i+1]) if key == target_key
        return nil if key >  target_key
        i += 2
      end

      nil
    end

    def find(items, method, key)
      Helper.binary_search(items, method, key, 0, items.count - 1)
    end

    def write_entries_to_file(entries)
      next_page_size = @pagesize
      str = ""
      @fences << entries[0].key
      entries.each_with_index do |entry, i|
        @bloom_filter.set(entry.key)

        if str.size + entry.key.to_s.size + entry.val.to_s.size + 2 > @pagesize
          padding = "*" * (next_page_size - str.length)
          IO.write(@file_name, str + padding, next_page_size - @pagesize)
          @fences << entries[i].key
          str = ""
          next_page_size += @pagesize
        end

        str += entry.key.to_s + "," + entry.val.to_s + "\n"
      end

      if str != ""
        IO.write(@file_name, str, next_page_size - @pagesize)
      end
    end
  end
end
