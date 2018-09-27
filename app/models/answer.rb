class Answer < ApplicationRecord
  has_many :question_answers, dependent: :destroy
  has_many :questions, through: :question_answers
  has_many :transitions
  has_many :results

  before_validation :set_key!, on: :create

  validates_presence_of :answer
  validates :key, presence: true, uniqueness: true

  # color constants
  COLORS = {
    'btn-primary': 'btn-primary',
    'btn-secondary': 'btn-secondary',
    'btn-positive': 'btn-positive',
    'btn-negative': 'btn-negative',
    'green': '#2ecc71',
    'light-green': '#40d47e',
    'dark-green': '#29b765',
    'red': '#e74c3c',
    'light-red': '#ea6153',
    'dark-red': '#e43725',
    'blue': '#208ac3',
    'light-blue': '#e4f1fe',
    'heavy-dark-blue': '#2c3e50',
    'gray': '#c9c9c9'
  }

  LABELS = {
    'pro-vaccine': 'pro-vaccine',
    'anti-vaccine': 'anti-vaccine',
    'neutral': 'neutral',
    'relevant': 'relevant',
    'non-relevant': 'non-relevant'
  }

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
