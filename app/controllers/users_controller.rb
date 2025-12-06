class UsersController < ApplicationController
  def setup
    result = Users::SetupService.call(auth_header: request.headers['Authorization'])
    render json: result, status: :ok
  end
end
