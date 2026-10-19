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
    # Where saving, cancelling or deleting a job or an entry goes, by its date: Today for today, and that day's
    # report for a day before. Cancelar takes the date saved, which a failed change of date leaves as it was.
    def record_return_path(date)
      date == Date.current ? root_path : report_path("day", date)
    end

    # The shop comes from the signed-in user: URLs carry no shop.
    def set_current_shop
      set_current_tenant(Current.user.shop) if authenticated?
    end
end
