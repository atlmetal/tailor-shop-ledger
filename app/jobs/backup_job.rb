# Scheduled every night in config/recurring.yml. Then it pings the Healthchecks.io check that expects it
# on the same schedule, or the check's /fail URL when the backup fails: Healthchecks.io emails when a
# night's ping fails or doesn't arrive, and Sentry gets the error. `BackupJob.perform_now` in
# `bin/kamal console` takes one by hand.
class BackupJob < ApplicationJob
  def perform
    Backups::CreateService.call
  rescue
    ping "/fail"
    raise
  else
    ping
  end

  private
    # Net::HTTP keeps the check's URL off the command line, like the backup's keys; a response other
    # than a success raises.
    def ping(path = "")
      Net::HTTP.get_response(URI(Rails.application.credentials.fetch(:healthchecks).fetch(:ping_url) + path)).value
    end
end
