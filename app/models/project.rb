class Project < ApplicationRecord
  extend FriendlyId
  friendly_id :title, use: :slugged
  has_many :questions
  has_many :transitions
  has_many :results

  has_attached_file :image, styles: {
    thumb: '100x100>',
    square: '200x200#',
    medium: '300x300>'
  }

  translates :title, :description

  validates_presence_of :title, :description
  validates_attachment_content_type :image, :content_type => /\Aimage\/.*\Z/

  default_scope { order(created_at: :asc)  }

  def initial_question
    first_transition = transitions.find_by(from_question: nil)
    raise "Project #{self.title} does not have a valid first Question" if first_transition.nil?
    first_transition.to_question
  end
end
