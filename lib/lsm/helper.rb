# frozen_string_literal: true

module LSM
  class Helper
    class << self
      def system_pagesize
        @system_pagesize ||= `pagesize`.to_i
      end

      def mktemp(pattern)
        `mktemp "#{pattern}"`.split[0]
      end

      def binary_search(items, method, key, s, e)
        return s - 1 if s - e == 1

        middle_index = (s + e) / 2
        middle = items[middle_index]

        return middle_index if middle.send(method) == key

        if middle.send(method) < key
          binary_search(items, method, key, middle_index + 1, e)
        else
          binary_search(items, method, key, s, middle_index - 1)
        end
      end
    end
  end
end
