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

  describe 'fences' do
    let(:run) { LSM::Run.new }

    it 'set fences' do
      run.instance_variable_set("@pagesize", 12)
      entries = []

      9.times do |i|
        entries << LSM::Entry.new(i, i)
      end

      run.entries = entries
      run.save_to_file

      expect(run.fences).to eq [0, 3, 6]
    end

    it 'set fences' do
      run.instance_variable_set("@pagesize", 8)
      entries = []

      5.times do |i|
        entries << LSM::Entry.new(i, i)
      end

      run.entries = entries
      run.save_to_file

      expect(run.fences).to eq [0, 2, 4]
    end

    describe 'query through fences' do
      before do
        @run = LSM::Run.new
        @run.instance_variable_set("@pagesize", 12)

        entries = []

        9.times do |i|
          entries << LSM::Entry.new(i, i)
        end

        @run.entries = entries
        @run.save_to_file
      end

      it 'happy path' do
        expect(@run).to receive(:read_from_file).with(0).and_call_original
        expect(@run.get(0).val).to eq "0"

        expect(@run).to receive(:read_from_file).with(12).and_call_original
        expect(@run.get(3).val).to eq "3"
      end

      it 'sad path' do
        expect(@run.get(1024)).to eq nil
      end
    end
  end
end
