# frozen_string_literal: true

module LSM
  class MemTable
    attr_reader :entries

    def initialize(max_size=10)
      @max_size = max_size
      @entries = []
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

    def put(key, val)
      index = find(key)
      entry = @entries[index]

      if entry && entry.key == key
        @entries[index].val = val
      else
        return false if @entries.count >= @max_size

        entry = Entry.new(key, val)
        @entries = @entries[...index] + [entry] + @entries[index...]
      end
    end

    def empty
      @entries = []
    end

    def to_s
      table = []

      table[0] = ["MemTable(in memory): entries count=#{entries.length}"]

      @entries.each do |entry|
        table << "key=#{entry.key}, val=#{entry.val}"
      end

      table.join "\n"
    end

    private
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
  end
end
