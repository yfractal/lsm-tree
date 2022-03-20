# frozen_string_literal: true

RSpec.describe LSM::Buffer do
  describe 'put' do
    let(:buffer) { LSM::Buffer.new }

    it 'one key' do
      buffer.put(1, '10')

      expect(buffer.entries.count).to eq 1
    end

    it 'two keys' do
      buffer.put(1, '10')
      buffer.put(3, '30')

      entries = buffer.entries
      expect(entries.count).to eq 2
      expect(entries[0].key).to eq 1
      expect(entries[1].key).to eq 3
    end

    it 'three keys' do
      buffer.put(1, '10')
      buffer.put(3, '30')
      buffer.put(2, '30')

      entries = buffer.entries
      expect(entries.count).to eq 3
      expect(entries[0].key).to eq 1
      expect(entries[1].key).to eq 2
      expect(entries[2].key).to eq 3
    end

    it 'update value' do
      buffer.put(1, '10')
      entries = buffer.entries
      expect(entries.count).to eq 1
      expect(entries[0].val).to eq '10'

      buffer.put(1, '20')
      entries = buffer.entries
      expect(entries.count).to eq 1
      expect(entries[0].val).to eq '20'
    end
  end

  describe 'get' do
    let(:buffer) { LSM::Buffer.new }

    it 'exist' do
      buffer.put(1, '10')
      entry = buffer.get(1)

      expect(entry.key).to eq 1
      expect(entry.val).to eq '10'
    end

    it 'not exist' do
      entry = buffer.get(1)
      expect(entry).to eq nil
    end
  end
end
