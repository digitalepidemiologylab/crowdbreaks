class Answer < ApplicationRecord
  has_many :answer_sets
  has_many :transitions

  before_validation :set_key


  def display_name
    answer
  end

  private

  def set_key
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
    self.key = key
  end
end
