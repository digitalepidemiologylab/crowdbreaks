class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable, :lockable

  has_many :results
  has_and_belongs_to_many :local_batch_jobs

  validates_uniqueness_of :email
  validates :honeypot, absence: true

  enum role: [:default, :contributor, :collaborator, :admin, :super_admin]
  @skip = false
  attr_accessor :mark_as_confirmed, :honeypot

  scope :exclude_guests, -> {where('email !~ ?', 'guest_\d+@example.com')}


  def user_email
    "#{username} (#{email})"
  end

  # methods needed to get around devise validations/notifications on create
  # compare here: https://github.com/plataformatec/devise/wiki/How-to-manage-users-with-a-standard-Rails-controller
  def skip_notifications!()
    skip_confirmation_notification!
    @skip = true
  end

  def email_changed?
    return false if @skip
    super
  end

  def encrypted_password_changed?
    return false if @skip
    super
  end
end
