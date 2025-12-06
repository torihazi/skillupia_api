class ApplicationError < StandardError
  attr_reader :context, :http_status

  def initialize(message = nil, context: {}, http_status: nil)
    @context = context
    @http_status = http_status || self.class.http_status
    super(message || default_message)
  end

  def self.http_status
    500
  end

  def http_status
    @http_status || self.class.http_status
  end

  # i18nキーを生成（クラス名から自動生成）
  def i18n_key
    "errors.application_error.#{self.class.name.demodulize.underscore}"
  end

  # フロントエンド用のuser-friendlyなメッセージを取得
  def user_message
    I18n.t(i18n_key, default: default_message, **i18n_options)
  end

  private

  def default_message
    self.class.name.demodulize.humanize
  end

  def i18n_options
    {}.tap do |options|
      options[:external_status] = context[:external_status] if context[:external_status]
    end
  end
end

