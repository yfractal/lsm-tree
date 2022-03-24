# frozen_string_literal: true

module LSM
  class Run
    attr_reader :file_name, :fences
    attr_accessor :entries

    def initialize
      @entries = []
      @fences = []
      @pagesize = Helper.system_pagesize
      @file_name = Helper.mktemp("/tmp/lsm-XXXXXX")
    end

    def get(key)
      fence = find(fences, :itself, key)
      fence = [fence, fences.length - 1].min

      find_in_file(key, fence * @pagesize)
    end

    def save_to_file
      write_entries_to_file(@entries)
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
      size = 0
      next_page_size = @pagesize
      str = ""
      @fences << entries[0].key
      entries.each_with_index do |entry, i|
        if size + entry.key.to_s.size + entry.val.to_s.size + 2 > next_page_size
          IO.write(@file_name, str, next_page_size - @pagesize)
          @fences << entries[i].key
          str = ""
          next_page_size += @pagesize
        end

        size += entry.key.to_s.size + entry.val.to_s.size + 2
        str += entry.key.to_s + "," + entry.val.to_s + "\n"
      end

      if str != ""
        IO.write(@file_name, str, next_page_size - @pagesize)
      end
    end

    def read_from_file(offset)
      IO.read(@file_name, @pagesize, offset).split(/\n|,/)
    end
  end
end
