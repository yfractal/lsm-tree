# frozen_string_literal: true

RSpec.describe LSM::LSMTree do
  describe 'put' do
    let(:tree) { LSM::LSMTree.new(2) }

    it 'put in buffer' do
      tree.put(1, '10')

      buffer = tree.buffer
      expect(buffer.entries.count).to eq 1
    end

    it 'when buffer is full, put entries in level0' do
      tree.put(1, '10')
      tree.put(2, '20')

      expect(tree.buffer.entries.count).to eq 2

      tree.put(3, '30')
      # buffer is full
      expect(tree.buffer.entries.count).to eq 1

      tree.levels[0].runs
      expect(tree.levels[0].runs.count).to eq 1
      expect(tree.levels[0].runs[0].entries.count).to eq 2
    end
  end

  describe 'get' do
    let(:tree) { LSM::LSMTree.new(2) }

    it 'not exist' do
      entry = tree.get(1)

      expect(entry).to eq nil
    end

    it 'in buffer' do
      tree.put(1, '10')
      entry = tree.get(1)
      expect(entry.key).to eq 1
      expect(entry.val).to eq '10'
    end

    it 'in level0' do
      tree.put(1, '10')
      tree.put(2, '20')
      tree.put(3, '30')

      level0 = tree.levels[0]
      expect(level0.runs.count).to eq 1

      entry = tree.get(1)
      expect(entry.key).to eq 1
      expect(entry.val).to eq '10'
    end
  end
end
