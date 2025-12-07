class ApplicationError::InternalServerError < ApplicationError
  def self.http_status
    500
  end
end
