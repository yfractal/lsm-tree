# Tired LSM Tree

A Ruby implemented tired log-structured merge tree(LSM) for study purpose.

## Data Structure

## Operations

`LSM::LSMTree#put` is for writing key value pair into DB.

`LSM::LSMTree#get` is for query key into DB.

### Demo

Entry will be inserted into memtable first if the memtable is not full.

When the memtable is full, if we want to insert one more entry, DB will write the memtable to disk.

If level 0 is full, when we want to add one more sstable in level 0, DB will merge all level0's sstables into a big sstable, then the big sstable will be written into level 1.

This demo can be generated by the `./bin/demo` script.

## Implmented

## Future Plan
