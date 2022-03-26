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
    6.times do |i|
      sstable.entries << LSM::Entry.new(i, i)
    end
    sstable.save_to_file

    iterator = LSM::SSTableEntriesIterator.new(sstable)

    entries = []
    while entry = iterator.current_entry
      entries << entry
      iterator.next
    end

    expect(entries.count).to eq 6
    expect(entries.map(&:key)).to eq [0, 1, 2, 3, 4, 5]
  end
end
