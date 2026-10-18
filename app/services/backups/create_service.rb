module Backups
  # The nightly off-site backup: a pg_dump of the primary database, uploaded to a Cloudflare R2 bucket
  # whose lifecycle rule deletes it after 30 days. Cache, queue and cable aren't dumped: db:prepare
  # rebuilds them empty. pg_dump and curl come with the image, and curl signs the upload for R2's S3
  # API, so no gem is needed. Passwords and keys reach them through the environment and stdin, never
  # the command line.
  class CreateService < ApplicationService
    def initialize(database: ActiveRecord::Base.connection_db_config.configuration_hash, r2: Rails.application.credentials.fetch(:r2), now: Time.current)
      @database = database
      @r2 = r2
      @now = now
    end

    # The dump's name in the bucket.
    def call
      name = "#{@database[:database]}-#{@now.utc.strftime('%Y%m%dT%H%M%SZ')}.dump"
      Dir.mktmpdir do |dir|
        path = File.join(dir, name)
        run "pg_dump", "--format=custom", "--file=#{path}",
          env: { "PGHOST" => @database[:host], "PGUSER" => @database[:username], "PGPASSWORD" => @database[:password], "PGDATABASE" => @database[:database] }
        run "curl", "--config", "-", "--aws-sigv4", "aws:amz:auto:s3", "--upload-file", path, url(name), "--fail-with-body", "--silent", "--show-error", "--retry", "3",
          stdin_data: %(user = "#{@r2.fetch(:access_key_id)}:#{@r2.fetch(:secret_access_key)}")
      end
      name
    end

    private

    def url(name)
      "https://#{@r2.fetch(:account_id)}.r2.cloudflarestorage.com/#{@r2.fetch(:bucket)}/#{name}"
    end

    def run(*command, env: {}, **options)
      output, status = Open3.capture2e(env, *command, **options)
      raise "#{command.first} failed: #{output}" unless status.success?
    end
  end
end
