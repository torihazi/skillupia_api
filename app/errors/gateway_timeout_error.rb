class ApplicationError::GatewayTimeoutError < ApplicationError
  def self.http_status
    504
  end
end
