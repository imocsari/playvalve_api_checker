class CheckStatusService
  include ActiveModel::Validations

  attr_reader :idfa, :ip, :country, :rooted_device

  validates :idfa, :ip, :country, presence: true

  def initialize(idfa:, ip:, country:, rooted_device:)
    @idfa = idfa
    @ip = ip
    @country = country
    @rooted_device = rooted_device
  end

  def call
    return error_response(errors.full_messages.join(', ')) unless valid?

    user = find_or_initialize_user

    return banned_response(user.ban_status) if user.ban_status_banned?

    ban_status = determine_ban_status

    update_user_ban_status(user, ban_status)
  end

  private

  def find_or_initialize_user
    User.find_or_initialize_by(idfa:)
  end

  def determine_ban_status
    banned_conditions.any? ? 'banned' : 'not_banned'
  end

  def banned_conditions
    [
      rooted_device?,
      country_blacklisted?,
      vpn_check_service.banned?,
      manually_blacklisted?
    ]
  end

  def update_user_ban_status(user, ban_status)
    if user.new_record? || user.ban_status != User.ban_statuses[ban_status]
      user.ban_status = ban_status
      return error_response(user.errors.full_messages.join(', ')) unless user.save
    end

    log_integrity(ban_status)
    { ban_status: }
  end

  def rooted_device?
    ActiveModel::Type::Boolean.new.cast(rooted_device)
  end

  def country_blacklisted?
    Rails.logger.info("Checking country blacklist: #{country}")
    $redis.sismember('country_blacklist', country)
  end

  def manually_blacklisted?
    Rails.logger.info("Checking manual IP blacklist: #{ip}")
    $redis.sismember('manual_banned_ips', ip)
  end

  def vpn_check_service
    @vpn_check_service ||= VpnCheckService.new(ip)
  end

  def log_integrity(ban_status)
    IntegrityLogger.log(
      idfa:,
      ip:,
      country:,
      rooted_device: rooted_device?,
      vpn: vpn_check_service.banned?,
      proxy: false,
      ban_status:
    )
  end

  def error_response(message)
    { error: message }
  end

  def banned_response(ban_status)
    log_integrity(ban_status)
    { ban_status: 'banned' }
  end
end
