require "rails_helper"

RSpec.describe BackupJob do
  subject(:perform) { described_class.perform_now }

  let(:pinged) { instance_double(Net::HTTPOK, value: nil) }

  before do
    allow(Rails.application.credentials).to receive(:fetch).with(:healthchecks).and_return(ping_url: "https://hc-ping.com/check")
    allow(Backups::CreateService).to receive(:call)
    allow(Net::HTTP).to receive(:get_response).and_return(pinged)
  end

  it "backs the database up and pings Healthchecks.io" do
    perform

    expect(Backups::CreateService).to have_received(:call)
    expect(Net::HTTP).to have_received(:get_response).with(URI("https://hc-ping.com/check"))
  end

  context "when the backup fails" do
    before { allow(Backups::CreateService).to receive(:call).and_raise(RuntimeError, "pg_dump failed: connection refused") }

    it "pings the check's /fail URL and raises for Sentry" do
      expect { perform }.to raise_error(RuntimeError, "pg_dump failed: connection refused")
      expect(Net::HTTP).to have_received(:get_response).with(URI("https://hc-ping.com/check/fail"))
    end
  end

  context "when Healthchecks.io refuses the ping" do
    before { allow(pinged).to receive(:value).and_raise(Net::HTTPClientException.new("404 \"Not Found\"", pinged)) }

    it { expect { perform }.to raise_error(Net::HTTPClientException) }
  end
end
