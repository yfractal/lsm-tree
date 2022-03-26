# frozen_string_literal: true

RSpec.describe LSM::SSTableEntriesIterator do
  it 'one page entries' do
    sstable = LSM::SSTable.new
    3.times do |i|
      sstable.entries << LSM::Entry.new(i, i)
    end
    sstable.save_to_file

    iterator = LSM::SSTableEntriesIterator.new(sstable)

    entries = []
    while entry = iterator.current_entry
      entries << entry
      iterator.next
    end

    expect(entries.count).to eq 3
    expect(entries.map(&:key)).to eq [0, 1, 2]
  end

  it 'two pages entries' do
    sstable = LSM::SSTable.new
    sstable.entries << LSM::Entry.new(3, "3")
    sstable.entries << LSM::Entry.new(7, "7")
    sstable.entries << LSM::Entry.new(8, "8")
    sstable.instance_variable_set("@pagesize", 8)
    sstable.save_to_file
    expect(sstable.fences.count).to eq 2

    iterator = LSM::SSTableEntriesIterator.new(sstable)
    entries = []
    while entry = iterator.current_entry
      entries << entry
      iterator.next
    end

    expect(entries.map(&:key)).to eq [3, 7, 8]
  end
end
