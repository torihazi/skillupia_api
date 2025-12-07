class ApplicationError::ValidationError < ApplicationError
  def self.http_status
    422
  end
end

