# frozen_string_literal: true

module LSM
  class LSMTree
    def initialize(buffer_max_entries=5, run_max_entries=5, depth=5, fanout=5)
      @buffer_max_entries = buffer_max_entries
      @run_max_entries = run_max_entries
      @depth = depth
      @fanout = fanout

      @buffer = Buffer.new(@buffer_max_entries)

      @levels = []
      @depth.times do
        @levels << Level.new(fanout, @run_max_entries)
      end
    end

    def put(key, val)
    end

    def get(key)
    end
  end
end
