class MturkToken < ApplicationRecord
  has_secure_token  # defaults to token field
  has_secure_token :key

  before_create :set_tokens

  def self.validate_token(token)
    record = MturkToken.find_by(token: token)
    raise 'Invalid Token' unless record.present?
    raise 'Token was already used' if record.used?  
  end

  def self.return_key(token)
    record = MturkToken.find_by(token: token)
    record.key
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
