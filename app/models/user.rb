class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable, :lockable

  has_many :results
  has_and_belongs_to_many :local_batch_jobs

  validates_uniqueness_of :email

  def user_email
    "#{username} (#{email})"
  end
end
