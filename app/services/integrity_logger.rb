class IntegrityLogger
  def initialize(destination: :database)
    raise ArgumentError, 'Only :database supported so far' unless destination == :database

    @destination = destination
  end

  # Instance method that calls private method based on destination
  def log(idfa:, ip:, country:, rooted_device:, vpn:, proxy:, ban_status:)
    case @destination
    when :database
      log_to_database(idfa:, ip:, country:, rooted_device:, vpn:, proxy:, ban_status:)
    else
      raise "Unsupported destination: #{@destination}"
    end
  end

  # Class-level shortcut directly logging to database (no instance needed)
  def self.log(idfa:, ip:, country:, rooted_device:, vpn:, proxy:, ban_status:)
    IntegrityLog.create!(
      idfa:,
      ip:,
      country:,
      rooted_device:,
      vpn:,
      proxy:,
      ban_status: IntegrityLog.ban_statuses[ban_status]
    )
  end

  private

  # Private method to log to database
  def log_to_database(idfa:, ip:, country:, rooted_device:, vpn:, proxy:, ban_status:)
    IntegrityLog.create!(
      idfa:,
      ip:,
      country:,
      rooted_device:,
      vpn:,
      proxy:,
      ban_status: IntegrityLog.ban_statuses[ban_status]
    )
  end
end
