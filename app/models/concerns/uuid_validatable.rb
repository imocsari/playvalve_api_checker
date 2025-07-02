module UuidValidatable
  extend ActiveSupport::Concern

  included do
    validate :idfa_must_be_valid_uuid
  end

  private

  def idfa_must_be_valid_uuid
    return if idfa.blank?

    uuid_regex = /\A[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    errors.add(:idfa, 'must be a valid UUID') unless idfa.match?(uuid_regex)
  end
end
