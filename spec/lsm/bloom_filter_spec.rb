# frozen_string_literal: true

RSpec.describe LSM::BloomFilter do
  it 'check key exist' do
    filter = LSM::BloomFilter.new(10)

    expect(filter.has?(1)).to eq false

    filter.set(1)
    expect(filter.has?(1)).to eq true
  end
end
