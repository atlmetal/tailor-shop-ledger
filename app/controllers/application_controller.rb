class ApplicationController < ActionController::Base
  include Authentication
  set_current_tenant_through_filter
  before_action :set_current_shop

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :record_return_path

  private
    # Where saving, cancelling or deleting a job or an entry goes: Today, until the day's report exists (M7)
    # and takes the records of past days.
    def record_return_path(_record)
      root_path
    end

    # The shop comes from the signed-in user: URLs carry no shop.
    def set_current_shop
      set_current_tenant(Current.user.shop) if authenticated?
    end
end
