class ApplicationError::ForbiddenError < ApplicationError
  def self.http_status
    403
  end
end

