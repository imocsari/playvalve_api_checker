require 'faraday'
require 'json'

class VpnCheckService
  BASE_URL = 'https://vpnapi.io/api'.freeze
  CACHE_TTL = 24.hours
  DEFAULT_RESULT = { vpn: false, proxy: false, tor: false }.freeze

  def initialize(ip)
    @ip = ip
  end

  def banned?
    result = self.class.lookup(@ip)
    result[:vpn] || result[:proxy] || result[:tor]
  end

  class << self
    def lookup(ip)
      return DEFAULT_RESULT if ip.blank?

      fetch_cached(ip) || fetch_from_api(ip)
    end

    private

    def fetch_cached(ip)
      raw = $redis.get(cache_key(ip))
      JSON.parse(raw, symbolize_names: true) if raw
    rescue JSON::ParserError
      nil
    end

    def fetch_from_api(ip)
      response = Faraday.get("#{BASE_URL}/#{ip}", { key: api_key }, request_options)

      if response.status == 200
        result = extract_result(response.body)
        cache_result(ip, result)
        result
      else
        Rails.logger.warn("VPNAPI failed for IP #{ip} with status #{response.status}")
        DEFAULT_RESULT
      end
    rescue JSON::ParserError => e
      Rails.logger.error("VPNAPI JSON error: #{e.message}")
      DEFAULT_RESULT
    rescue StandardError => e
      Rails.logger.error("VPNAPI error: #{e.message}")
      DEFAULT_RESULT
    end

    def extract_result(body)
      json = JSON.parse(body)
      {
        vpn: json.dig('security', 'vpn') || false,
        proxy: json.dig('security', 'proxy') || false,
        tor: json.dig('security', 'tor') || false
      }
    end

    def cache_result(ip, result)
      $redis.setex(cache_key(ip), CACHE_TTL.to_i, result.to_json)
    end

    def cache_key(ip)
      "vpnapi:#{ip}"
    end

    def api_key
      ENV['VPNAPI_KEY'] || Rails.application.credentials.dig(:vpnapi, :key)
    end

    def request_options
      {
        request: {
          timeout: 3,
          open_timeout: 2
        }
      }
    end
  end
end
