class User < ApplicationRecord
  validates :uid, presence: true
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :image, presence: true
end
