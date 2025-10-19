module Api
  module V1
    class HealthController < ApplicationController
      def health
        render json: { message: "OK" }
      end
    end
  end
end