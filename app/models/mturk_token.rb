class MturkToken < ApplicationRecord
  has_secure_token  # defaults to token field
  has_secure_token :key

  before_create :set_tokens

  def self.validate_token(token)
    record = MturkToken.find_by(token: token)
    if !record.present?
      return false, "Invalid token"
    elsif record.used?
      return false, "Token was already used"
    else
      return true, ""
    end
  end

  def self.return_key(token)
    record = MturkToken.find_by(token: token)
    record.key
  end

  def self.update_answer_count(token, count)
    record = MturkToken.find_by(token: token)
    raise 'Record for token could not be found' unless record
    record.update_attributes!(questions_answered: count)
  end

  private

  def set_tokens
    self.token = generate_token('token')
    self.key = generate_token('key')
  end


  def generate_token(field)
    loop do
      token = SecureRandom.hex(10)
      break token unless MturkToken.where(field.to_sym => token).exists?
    end
  end
end
