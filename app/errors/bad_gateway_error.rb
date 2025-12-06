class ApplicationError::BadGatewayError < ApplicationError
  def self.http_status
    502
  end
end

