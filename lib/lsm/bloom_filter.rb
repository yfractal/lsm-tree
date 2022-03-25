# frozen_string_literal: true

require 'bitarray'

module LSM
  class BloomFilter
    def initialize(size)
      @size = size
      @table = BitArray.new(size)
    end

    def set(key)
      @table[hash_1(key)] = 1
      @table[hash_2(key)] = 1
      @table[hash_3(key)] = 1
    end

    def has?(key)
      @table[hash_1(key)] != 0 && @table[hash_2(key)] != 0 && @table[hash_3(key)] != 0
    end

    private
    # Hash functions are taken from https://gist.github.com/badboy/6267743
    def hash_1(key)
      key = ~key + (key<<15)
      key = key ^ (key>>12)
      key = key + (key<<2)
      key = key ^ (key>>4)
      key = key * 2057;
      key = key ^ (key>>16)

      key % @size
    end

    def hash_2(key)
      key = (key+0x7ed55d16) + (key<<12)
      key = (key^0xc761c23c) ^ (key>>19)
      key = (key+0x165667b1) + (key<<5)
      key = (key+0xd3a2646c) ^ (key<<9)
      key = (key+0xfd7046c5) + (key<<3)
      key = (key^0xb55a4f09) ^ (key>>16)

      key % @size
    end

    def hash_3(key)
      key = (key^61) ^ (key>>16)
      key = key + (key<<3)
      key = key ^ (key>>4)
      key = key * 0x27d4eb2d
      key = key ^ (key>>15)

      key % @size
    end
  end
end
