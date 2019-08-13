class ApplicationController < ActionController::API

  include ActionController::HttpAuthentication::Token::ControllerMethods

  before_action :authenticate

  after_action :reset_header

  private

  def authenticate_test
    @current_user = CurrentUser.build(JSON.parse(request.headers['HTTP_AUTHORIZATION'])) if request.headers['HTTP_AUTHORIZATION']
  end

  ##
  # Aus dem Service template von marcel übernommen und angepasst
  def authenticate
    request.headers['HTTP_AUTHORIZATION'] ||= "Bearer #{request.cookies[:token.to_s]}"

    begin
      auth_result = authenticate_with_http_token do |token, options|
        @token = token
        @jwt = JsonWebTokenService.decode token
        @current_user = CurrentUser.build @jwt['data']
        # ActiveResourceBearerTokenService.token = @token
      end
    rescue JWT::ExpiredSignature
      headers.delete 'Authorization'
      head :unauthorized
    end
    if auth_result
      return @user
    else
      request_http_token_authentication
    end
  end

  def reset_header
    # ActiveResourceBearerTokenService.token = @token
  end

  def current_user
    @current_user || authenticate
  end
end
