# frozen_string_literal: true

module LSM
  class Run
    attr_reader :entries, :file_name
    # TODO: handle disk

    def initialize(entries = [])
      @entries = entries
      @pagesize = `pagesize`.to_i
      @file_name = `mktemp "/tmp/lsm-XXXXXX"`.split[0]
    end

    def get(key)
      index = find(key)
      entry = @entries[index]

      if entry && entry.key == key
        entry
      else
        nil
      end
    end

    def <<(entry)
      @entries << entry
    end

    private
    # TODO: remove duplicate code
    def find(key)
      binary_search(key, 0, @entries.count - 1)
    end

    def binary_search(key, s, e)
      return s if s - e == 1

      middle_index = (s + e) / 2
      middle = @entries[middle_index]

      if middle.key == key
        middle_index
      elsif middle.key < key
        binary_search(key, middle_index + 1, e)
      else
        binary_search(key, s, middle_index - 1)
      end
    end

    private
    def write_entries_to_file(entries)
      size = 0
      next_page_size = @pagesize
      str = ""

      entries.each_with_index do |entry, i|
        if size + entry.key.to_s.size + entry.val.to_s.size + 2 > next_page_size
          IO.write(@file_name, str, next_page_size - @pagesize)
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
