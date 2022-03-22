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

    def to_s
      table = []
      table[0] = @runs.map do |run|
        str = "Run: count=#{run.entries.count}"
        str + " " * (20 - str.length)
      end

      i = 1
      while true
        has_entrie = false
        table[i] = []
        @runs.each do |run|
          entry = run.entries[i]

          if entry != nil
            has_entrie = true
            str = "key=#{entry.key}, val=#{entry.val}"

            table[i] << str + " " * (20 - str.length)
          else
            table[i] << ""
          end
        end

        break if has_entrie == false
        i += 1
      end

      table.map{|row| row.join("  ") }.join("\n")
    end
  end
end
