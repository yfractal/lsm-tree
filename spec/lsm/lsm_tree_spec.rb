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

  describe 'merge_entries_list' do
    it 'case 1' do
      list1 = [LSM::Entry.new(2, '100')]
      list2 = [LSM::Entry.new(2, '10')]

      tree = LSM::LSMTree.new
      entries = tree.send(:merge_entries_list, [list1, list2])
      expect(entries.count).to eq 1
      expect(entries[0].val).to eq '100'
    end

    it 'case 2' do
      list1 = [LSM::Entry.new(1, '10')]
      list2 = [LSM::Entry.new(2, '20')]

      tree = LSM::LSMTree.new
      entries = tree.send(:merge_entries_list, [list1, list2])
      expect(entries.count).to eq 2
      expect(entries[0].val).to eq '10'
    end

    it 'case 3' do
      list1 = [LSM::Entry.new(2, '20')]
      list2 = [LSM::Entry.new(1, '10')]

      tree = LSM::LSMTree.new
      entries = tree.send(:merge_entries_list, [list1, list2])
      expect(entries.count).to eq 2
      expect(entries[0].val).to eq '10'
    end

    it 'merge 3 lists' do
      list1 = [LSM::Entry.new(3, '30')]
      list2 = [LSM::Entry.new(2, '20')]
      list3 = [LSM::Entry.new(1, '10')]

      tree = LSM::LSMTree.new
      entries = tree.send(:merge_entries_list, [list1, list2, list3])
      expect(entries.count).to eq 3
      expect(entries[0].val).to eq '10'
      expect(entries[1].val).to eq '20'
      expect(entries[2].val).to eq '30'
    end
  end

  describe 'merge_down' do
    before do
      @tree = LSM::LSMTree.new(2)

      entries1 = [LSM::Entry.new(1, '10'), LSM::Entry.new(2, '200')]
      entries2 = [LSM::Entry.new(1, '20')]
      @tree.levels[0].insert_entries(entries1)
      @tree.levels[0].insert_entries(entries2)
      @tree.send(:merge_down, 0, 1)
    end

    it 'merge entries and insert to next levels' do
      expect(@tree.levels[1].runs.count).to eq 1
      expect(@tree.levels[1].runs[0].entries.count).to eq 2
    end

    it 'empty current level' do
      expect(@tree.levels[0].runs.count).to eq 0
    end
  end

  describe 'random test' do
    it '1 level data' do
      tree = LSM::LSMTree.new(10, 1, 5)
      array = (0..29).to_a.shuffle

      array.each_with_index do |i, index|
        tree.put(i, i.to_s)
      end

      array.each do |i|
        expect(tree.get(i)&.val).to eq i.to_s
      end
    end

    it '2 level data' do
      tree = LSM::LSMTree.new(10, 2, 5)
      array = (0...310).to_a.shuffle

      array.each do |i|
        tree.put(i, i.to_s)
      end

      array.each do |i|
        expect(tree.get(i)&.val).to eq i.to_s
      end
    end

    it 'handle duplicate' do
      tree = LSM::LSMTree.new(10, 2, 5)
      array = (0...100).to_a.shuffle

      array.each do |i|
        tree.put(i, i.to_s)
      end

      array.each do |i|
        expect(tree.get(i)&.val).to eq i.to_s
      end

      array.each do |i|
        tree.put(i, (i * 10).to_s)
      end

      array.each do |i|
        expect(tree.get(i)&.val).to eq (i * 10).to_s
      end
    end
  end
end
