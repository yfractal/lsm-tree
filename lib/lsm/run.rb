# frozen_string_literal: true

module LSM
  class Run
    attr_reader :entries
    # TODO: handle disk

    def initialize(entries = [])
      @entries = entries
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
  end
end
