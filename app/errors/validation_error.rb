class ApplicationError::ValidationError < ApplicationError
  attr_reader :errors

  def initialize(message = nil, errors: {}, context: {})
    @errors = errors
    super(message, context: context)
  end

  def self.http_status
    422
  end
end

