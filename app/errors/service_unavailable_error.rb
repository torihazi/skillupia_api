class ApplicationError::ServiceUnavailableError < ApplicationError
  def self.http_status
    503
  end
end
