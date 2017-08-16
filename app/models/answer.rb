# == Schema Information
#
# Table name: answers
#
#  id                  :integer          not null, primary key
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  key                 :string
#  order               :integer          default(0)
#  answer_translations :jsonb
#

class Answer < ApplicationRecord
  has_many :answer_sets
  has_many :transitions
  has_many :results

  default_scope { order(order: :asc) }

  before_validation :set_key!

  validates_presence_of :answer
  validates :key, presence: true, uniqueness: true

  translates :answer

  # color constants
  COLORS = {
    'green': '#2ecc71',
    'red': '#e74c3c',
    'blue': '#208ac3',
    'dark-green': '#29b765',
    'dark-red': '#e43725',
    'light-blue': '#e4f1fe',
    'heavy-dark-blue': '#2c3e50',
    'white': '#ffffff',
    'gray': '#c9c9c9',
  }

  def display_name
    answer
  end

  private

  def set_key!
    # raise ActiveModel::ValidationError, "Answer can't be empty" unless answer
    return unless answer
    key = answer.strip.downcase

    # blow away apostrophes
    key.gsub!(/['`]/, '')
    # @ --> at, and & --> and
    key.gsub!(/\s*@\s*/, ' at ')
    key.gsub!(/\s*&\s*/, ' and ')
    # replace all non alphanumeric, underscore or periods with dash
    key.gsub!(/\s*[^A-Za-z0-9\.\_]\s*/, '-')
    # convert double dash to single
    key.gsub!(/-+/, '-')
    # strip off leading/trailing underscore
    key.gsub!(/\A[-\.]+|[-\.]+\z/, '')
    random_string = rand(36**8).to_s(36)
    self.key = key + '_' + random_string
  end
end
