# frozen_string_literal: true

RSpec.describe LSM::MemTable do
  describe 'put' do
    let(:mem_table) { LSM::MemTable.new }

    it 'one key' do
      mem_table.put(1, '10')

      expect(mem_table.entries.count).to eq 1
    end

    it 'two keys' do
      mem_table.put(1, '10')
      mem_table.put(3, '30')

      entries = mem_table.entries
      expect(entries.count).to eq 2
      expect(entries[0].key).to eq 1
      expect(entries[1].key).to eq 3
    end

    it 'two keys 2' do
      mem_table.put(9, 9)
      mem_table.put(1, 1)
      expect(mem_table.entries.map(&:key)).to eq [1, 9]
    end

    it 'three keys' do
      mem_table.put(1, '10')
      mem_table.put(3, '30')
      mem_table.put(2, '30')

      entries = mem_table.entries
      expect(entries.count).to eq 3
      expect(entries[0].key).to eq 1
      expect(entries[1].key).to eq 2
      expect(entries[2].key).to eq 3
    end

    it 'update value' do
      mem_table.put(1, '10')
      entries = mem_table.entries
      expect(entries.count).to eq 1
      expect(entries[0].val).to eq '10'

      mem_table.put(1, '20')
      entries = mem_table.entries
      expect(entries.count).to eq 1
      expect(entries[0].val).to eq '20'
    end
  end

  describe 'get' do
    let(:mem_table) { LSM::MemTable.new }

    it 'exist' do
      mem_table.put(1, '10')
      entry = mem_table.get(1)

      expect(entry.key).to eq 1
      expect(entry.val).to eq '10'
    end

    it 'not exist' do
      entry = mem_table.get(1)
      expect(entry).to eq nil
    end
  end

  describe 'random data' do
    let(:mem_table) { LSM::MemTable.new 1000 }

    it 'no duplidate' do
      array = (0..999).to_a

      array.shuffle.each do |i|
        mem_table.put(i, i)
      end

      expect(mem_table.entries.map(&:key)).to eq (0..999).to_a
    end

    it 'with duplidate' do
      array = (0..999).to_a

      array.shuffle.each do |i|
        mem_table.put(i, i)
      end

      array.shuffle.each do |i|
        mem_table.put(i, i * 10)
      end

      expect(mem_table.entries.map(&:val)).to eq (0..999).to_a.map { |i| i * 10 }
    end
  end
end
