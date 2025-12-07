class ApplicationError::NotFoundError < ApplicationError
  def self.http_status
    404
  end
end
