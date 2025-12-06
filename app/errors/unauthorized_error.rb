class ApplicationError::UnauthorizedError < ApplicationError
  def self.http_status
    401
  end
end

