module V1
  class UsersController < ApplicationController
    wrap_parameters false

    def check_status
      idfa = params[:idfa]
      ip = extract_client_ip || params[:ip]
      country = params[:country] || request.headers['CF-IPCountry']
      rooted_device = cast_rooted_device(params[:rooted_device])

      return missing_param(:idfa) if idfa.blank?
      return missing_param(:ip) if ip.blank?
      return missing_param(:country) if country.blank?

      result = CheckStatusService.new(
        idfa:,
        ip:,
        country:,
        rooted_device:
      ).call

      return render json: { error: result[:error] }, status: :bad_request if result[:error]
      return render json: { error: 'banned' }, status: :forbidden if result[:ban_status] == 'banned'

      render json: result
    end

    private

    def extract_client_ip
      request.headers['X-Forwarded-For']&.split(',')&.first&.strip ||
        params[:ip] ||
        request.remote_ip
    end

    def cast_rooted_device(value)
      ActiveModel::Type::Boolean.new.cast(
        request.headers['X-Device-Rooted'] || value
      )
    end

    def missing_param(param)
      render json: { error: "Missing required parameter: #{param}" }, status: :bad_request
    end
  end
end
