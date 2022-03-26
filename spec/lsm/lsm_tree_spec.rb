# frozen_string_literal: true

RSpec.describe LSM::LSMTree do
  describe 'put' do
    let(:tree) { LSM::LSMTree.new(2) }

    it 'put in mem_table' do
      tree.put(1, '10')

      mem_table = tree.mem_table
      expect(mem_table.entries.count).to eq 1
    end

    it 'when mem_table is full, put entries in level0' do
      tree.put(1, '10')
      tree.put(2, '20')

      expect(tree.mem_table.entries.count).to eq 2

      tree.put(3, '30')
      # mem_table is full
      expect(tree.mem_table.entries.count).to eq 1

      tree.levels[0].sstables
      expect(tree.levels[0].sstables.count).to eq 1
      expect(tree.levels[0].sstables[0].entries.count).to eq 2
    end
  end

  describe 'get' do
    let(:tree) { LSM::LSMTree.new(2) }

    it 'not exist' do
      entry = tree.get(1)

      expect(entry).to eq nil
    end

    it 'in mem_table' do
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
      expect(level0.sstables.count).to eq 1

      entry = tree.get(1)
      expect(entry.key).to eq 1
      expect(entry.val).to eq '10'
    end
  end

  describe 'merge_sstables_helper' do
    let(:tree) { LSM::LSMTree.new }

    it 'no more entries' do
      sstable = LSM::SSTable.new
      iterator = LSM::SSTableEntriesIterator.new(sstable)

      _, entries = tree.send(:merge_sstables_helper, [iterator], [])
      expect(entries).to eq []
    end

    it 'one iterator in queue' do
      sstable = LSM::SSTable.new
      3.times do |i|
        sstable.entries << LSM::Entry.new(i, i)
      end
      sstable.save_to_file
      iterator = LSM::SSTableEntriesIterator.new(sstable)

      _, entries = tree.send(:merge_sstables_helper, [iterator], [])
      expect(entries.count).to eq 3
      expect(entries.map(&:key)).to eq [0, 1, 2]
    end

    it 'first iterator in queue has no element' do
      sstable = LSM::SSTable.new
      3.times do |i|
        sstable.entries << LSM::Entry.new(i, i)
      end
      sstable.save_to_file
      iterator = LSM::SSTableEntriesIterator.new(sstable)

      sstable1 = LSM::SSTable.new
      iterator1 = LSM::SSTableEntriesIterator.new(sstable1)

      _, entries = tree.send(:merge_sstables_helper, [iterator1, iterator], [])

      expect(entries.map(&:key)).to eq [0]
      expect(iterator.current_entry.key).to eq 1
    end

    describe 'merge one entry' do
      it 'same key' do
        sstable = LSM::SSTable.new
        sstable.entries << LSM::Entry.new(1, "10")
        sstable.save_to_file

        iterator = LSM::SSTableEntriesIterator.new(sstable)

        sstable1 = LSM::SSTable.new
        sstable1.entries << LSM::Entry.new(1, "1")
        sstable1.save_to_file
        iterator1 = LSM::SSTableEntriesIterator.new(sstable1)

        _, entries = tree.send(:merge_sstables_helper, [iterator, iterator1], [])

        expect(entries[0].val).to eq "10"

        expect(iterator.current_entry).to eq nil
        expect(iterator1.current_entry).to eq nil
      end

      it 'small key' do
        sstable = LSM::SSTable.new
        sstable.entries << LSM::Entry.new(1, "10")
        sstable.save_to_file

        iterator = LSM::SSTableEntriesIterator.new(sstable)

        sstable1 = LSM::SSTable.new
        sstable1.entries << LSM::Entry.new(2, "20")
        sstable1.save_to_file
        iterator1 = LSM::SSTableEntriesIterator.new(sstable1)

        _, entries = tree.send(:merge_sstables_helper, [iterator, iterator1], [])

        expect(entries[0].val).to eq "10"

        expect(iterator.current_entry).to eq nil
        expect(iterator1.current_entry).not_to eq nil
      end

      it 'has bigger key' do
        sstable = LSM::SSTable.new
        sstable.entries << LSM::Entry.new(2, "20")
        sstable.save_to_file

        iterator = LSM::SSTableEntriesIterator.new(sstable)

        sstable1 = LSM::SSTable.new
        sstable1.entries << LSM::Entry.new(1, "10")
        sstable1.save_to_file
        iterator1 = LSM::SSTableEntriesIterator.new(sstable1)

        _, entries = tree.send(:merge_sstables_helper, [iterator, iterator1], [])

        expect(entries.count).to eq 1

        expect(iterator.current_entry).not_to eq nil
        expect(iterator1.current_entry).to eq nil
      end
    end
  end

  describe 'merge_sstables' do
    let(:tree) { LSM::LSMTree.new }

    describe 'merge 2 sstabels' do
      it 'case 1' do
        sstable = LSM::SSTable.new
        sstable.entries << LSM::Entry.new(2, "20")
        sstable.save_to_file

        sstable1 = LSM::SSTable.new
        sstable1.entries << LSM::Entry.new(1, "10")
        sstable1.save_to_file

        level = LSM::Level.new(2)
        level.sstables = [sstable, sstable1]

        entries = tree.send(:merge_sstables, level)

        expect(entries.count).to eq 2
        expect(entries.map(&:key)).to eq [1, 2]
        expect(entries.map(&:val)).to eq ["10", "20"]
      end

      it 'case 2' do
        sstable = LSM::SSTable.new
        sstable.entries << LSM::Entry.new(1, "10")
        sstable.save_to_file

        sstable1 = LSM::SSTable.new
        sstable1.entries << LSM::Entry.new(1, "1")
        sstable1.save_to_file

        level = LSM::Level.new(2)
        level.sstables = [sstable, sstable1]

        entries = tree.send(:merge_sstables, level)

        expect(entries.count).to eq 1
        expect(entries.map(&:key)).to eq [1]
        expect(entries.map(&:val)).to eq ["10"]
      end
    end

    it 'case 3' do
      sstable = LSM::SSTable.new
      sstable.entries << LSM::Entry.new(3, "3")
      sstable.entries << LSM::Entry.new(7, "7")
      sstable.entries << LSM::Entry.new(8, "8")
      # sstable.instance_variable_set("@pagesize", 8)
      sstable.save_to_file
      # expect(sstable.fences.count).to eq 2

      sstable1 = LSM::SSTable.new
      sstable1.entries << LSM::Entry.new(1, "10")
      sstable1.entries << LSM::Entry.new(5, "50")
      sstable1.entries << LSM::Entry.new(6, "60")
      sstable1.entries << LSM::Entry.new(7, "70")
      sstable1.entries << LSM::Entry.new(9, "90")
      sstable1.save_to_file

      sstable2 = LSM::SSTable.new
      sstable2.entries << LSM::Entry.new(1, "200")
      sstable2.entries << LSM::Entry.new(2, "200")
      sstable2.entries << LSM::Entry.new(4, "400")
      sstable2.entries << LSM::Entry.new(9, "900")
      sstable2.save_to_file

      level = LSM::Level.new(3)
      level.sstables = [sstable, sstable1, sstable2]

      entries = tree.send(:merge_sstables, level)
      expect(entries.map(&:key)).to eq [1, 2, 3, 4, 5, 6, 7, 8, 9]
      expect(entries.map(&:val)).to eq ["10", "200", "3", "400", "50", "60", "7", "8", "90"]
    end

    it 'more than one page' do
      sstable = LSM::SSTable.new
      sstable.entries << LSM::Entry.new(3, "3")
      sstable.entries << LSM::Entry.new(7, "7")
      sstable.entries << LSM::Entry.new(8, "8")
      sstable.instance_variable_set("@pagesize", 8)
      sstable.save_to_file
      expect(sstable.fences.count).to eq 2

      sstable1 = LSM::SSTable.new
      sstable1.entries << LSM::Entry.new(1, "10")
      sstable1.save_to_file

      level = LSM::Level.new(2)
      level.sstables = [sstable, sstable1]

      entries = tree.send(:merge_sstables, level)
      expect(entries.map(&:key)).to eq [1, 3, 7, 8]
      expect(entries.map(&:val)).to eq ["10", "3", "7", "8"]
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
      expect(@tree.levels[1].sstables.count).to eq 1
      expect(@tree.levels[1].sstables[0].entries.count).to eq 2
    end

    it 'empty current level' do
      expect(@tree.levels[0].sstables.count).to eq 0
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
