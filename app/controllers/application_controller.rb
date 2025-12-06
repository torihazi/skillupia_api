class ApplicationController < ActionController::API
  rescue_from StandardError, with: :handle_standard_error

  private

  def handle_standard_error(error)
    Rails.logger.error "Standard error occurred: #{error.message}\n#{error.backtrace.join("\n")}"
    render json: { error: 'An unexpected error occurred' }, status: :internal_server_error
  end
end
