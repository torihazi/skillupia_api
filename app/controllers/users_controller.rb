class UsersController < ApplicationController
  def setup
    result = Users::SetupService.call(auth_header: request.headers['Authorization'])

    if result.success?
      render json: result.user, status: result.status
    else
      render json: { error: result.error }, status: result.status
    end
  end
end
