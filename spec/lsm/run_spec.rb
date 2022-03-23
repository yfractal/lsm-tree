# frozen_string_literal: true

RSpec.describe LSM::Run do
  describe 'read write file' do
    let(:run) { LSM::Run.new }

    it 'write file less pagesize' do
      entries = [LSM::Entry.new(1, 2)]
      run.send(:write_entries_to_file, entries)
      raw = run.send(:read_from_file, 0)
      expect(raw).to eq raw
    end

    it 'one page' do
      entries = []

      (`pagesize`.to_i / 4).times do
        entries << LSM::Entry.new(1, 1)
      end

      run.send(:write_entries_to_file, entries)
      raw = run.send(:read_from_file, 0)
      expect(raw).to eq ["1"] * (`pagesize`.to_i / 4) * 2
    end

    it 'more than one page' do
      entries = []

      (`pagesize`.to_i / 4).times do
        entries << LSM::Entry.new(1, 1)
      end

      entries << LSM::Entry.new(2, 2)
      run.send(:write_entries_to_file, entries)
      first_raw = run.send(:read_from_file, 0)
      expect(first_raw).to eq ["1"] * (`pagesize`.to_i / 4) * 2

      second_raw = run.send(:read_from_file, `pagesize`.to_i)
      expect(second_raw).to eq ["2", "2"]
    end
  end
end
