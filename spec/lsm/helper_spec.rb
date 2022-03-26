RSpec.describe LSM::Helper do
  describe 'binary_search' do
    it {
      index = LSM::Helper.binary_search([0, 2], :itself, 0, 0, 1)
      expect(index).to eq 0

      index = LSM::Helper.binary_search([0, 2, 4, 6, 8], :itself, 1, 0, 4)
      expect(index).to eq 0

      index = LSM::Helper.binary_search([0, 2, 4, 6, 8], :itself, 2, 0, 4)
      expect(index).to eq 1

      index = LSM::Helper.binary_search([0, 2, 4, 6, 8], :itself, 3, 0, 4)
      expect(index).to eq 1

      index = LSM::Helper.binary_search([0, 2, 4, 6, 8], :itself, 4, 0, 4)
      expect(index).to eq 2

      index = LSM::Helper.binary_search([0, 2, 4, 6, 8], :itself, 8, 0, 4)
      expect(index).to eq 4

      index = LSM::Helper.binary_search([0, 2, 4, 6, 8], :itself, 9, 0, 4)
      expect(index).to eq 4
    }
  end
end
