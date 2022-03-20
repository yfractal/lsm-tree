# frozen_string_literal: true

module LSM
  class Entry
    attr_accessor :key, :val

    def initialize(key, val)
      @key = key
      @val = val
    end

    def <=>(obj)
      self.key <=> obj.key
    end
  end
end
