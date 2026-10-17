class ApplicationController < ActionController::Base
  include Authentication
  set_current_tenant_through_filter
  before_action :set_current_shop

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private
    # The shop comes from the signed-in user: URLs carry no shop.
    def set_current_shop
      set_current_tenant(Current.user.shop) if authenticated?
    end
end
