require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      user = create(:user)
      expect(user).to be_valid
    end

    it 'is not valid without a uid' do
      user = build(:user, uid: nil)
      expect(user).to be_invalid
    end

    it 'is not valid without a name' do
      user = build(:user, name: nil)
      expect(user).to be_invalid
    end

    it 'is not valid without an email' do
      user = build(:user, email: nil)
      expect(user).to be_invalid
    end

    it 'is not valid without an image' do
      user = build(:user, image: nil)
      expect(user).to be_invalid
    end

    it 'is not valid with a duplicate email' do
      create(:user, email: 'test@example.com')
      user = build(:user, email: 'test@example.com')
      expect(user).to be_invalid
    end

    it 'is valid with a unique email' do
      create(:user, email: 'test1@example.com')
      user = build(:user, email: 'test2@example.com')
      expect(user).to be_valid
    end
  end
end
