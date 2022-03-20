# frozen_string_literal: true

module LSM
  class Level
    def initialize(fanout, run_max_entries)
      @fanout = fanout
      @run_max_entries = run_max_entries

      @runs = []
      fanout.times do
        Run.new(run_max_entries)
      end
    end
  end
end
