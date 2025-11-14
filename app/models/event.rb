class Event < ApplicationRecord
  # Protect database-managed fields from user modification
  attr_readonly :id

  # Prevent user from setting timestamps directly
  # Rails will manage these automatically
  before_validation :clear_timestamps_from_params, on: [ :create, :update ]

  private

  def clear_timestamps_from_params
    # Remove timestamps if they were set via mass assignment
    # Rails will set them automatically
    if will_save_change_to_created_at?
      restore_attribute!(:created_at)
    end
    # updated_at is always managed by Rails, so we don't need to protect it
    # as it will be overwritten on save anyway
  end
end
