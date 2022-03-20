# frozen_string_literal: true

module LSM
  class LSMTree
    attr_reader :buffer, :levels

    def initialize(buffer_max_entries=5, depth=5, fanout=5)
      @buffer_max_entries = buffer_max_entries
      @depth = depth
      @fanout = fanout

      @buffer = Buffer.new(@buffer_max_entries)

      @levels = []
      @depth.times do
        @levels << Level.new(fanout)
      end
    end

    def get(key)
      entry = @buffer.get(key)
      return entry if entry

      level0 = @levels[0]
      level0.get(key)
    end

    def put(key, val)
      return true if @buffer.put(key, val)

      level0 = @levels[0]

      level0.insert_entries(@buffer.entries)

      @buffer.empty
      @buffer.put(key, val)
    end
  end
end
