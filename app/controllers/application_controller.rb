class ApplicationController < ActionController::API
  rescue_from StandardError, with: :handle_standard_error
  rescue_from ApplicationError, with: :handle_application_error

  private

  def handle_application_error(error)
    # サーバー側: 詳細ログ
    Rails.logger.error({
      error_class: error.class.name,
      message: error.message
    }.to_json)

    # フロント側: user-friendlyなメッセージ
    render json: {
      error: error.user_message,
      code: error.class.name.demodulize.underscore.upcase
    }, status: error.http_status
  end

  def handle_standard_error(error)
    # サーバー側: 詳細ログ
    Rails.logger.error({
      error_class: error.class.name,
      message: error.message
    }.to_json)

    # フロント側: 汎用的なエラーメッセージ
    render json: {
      error: I18n.t("errors.application_error.internal_server_error", default: "An unexpected error occurred"),
      code: "INTERNAL_SERVER_ERROR"
    }, status: :internal_server_error
  end
end
