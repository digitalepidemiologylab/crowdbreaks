module Services
  class Tweet
    attr_reader :id, :text

    def initialize(id:, text:)
      raise(ArgumentError, 'text is not a string') unless text.is_a? String

      @id = Integer(id)
      @text = text
    end
  end
end
