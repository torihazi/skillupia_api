class ApplicationError::BadRequestError < ApplicationError
  def self.http_status
    400
  end
end
