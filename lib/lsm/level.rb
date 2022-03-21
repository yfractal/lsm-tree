# frozen_string_literal: true

module LSM
  class Level
    attr_accessor :runs

    def initialize(fanout)
      @fanout = fanout
      @runs = []
    end

    def insert_entries(entries)
      run = Run.new(entries)
      @runs = [run] + @runs
    end

    def insert_run(run)
      @runs = [run] + @runs
    end

    def get(key)
      @runs.each do |run|
        entry = run.get(key)
        return entry if entry
      end

      nil
    end

    def empty
      @runs = []
    end

    def full?
      @runs.count == @fanout
    end
  end
end
