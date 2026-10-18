require "rails_helper"

RSpec.describe Backups::CreateService do
  subject(:call) { described_class.call(database:, r2:, now: Time.utc(2026, 10, 16, 8)) }

  let(:database) { { host: "db", database: "tailor_shop_ledger_production", username: "tailor_shop_ledger", password: "db-password" } }
  let(:r2) { { account_id: "account", bucket: "backups", access_key_id: "key-id", secret_access_key: "secret-key" } }
  let(:path) { "/tmp/backup/tailor_shop_ledger_production-20261016T080000Z.dump" }
  let(:environment) { { "PGHOST" => "db", "PGUSER" => "tailor_shop_ledger", "PGPASSWORD" => "db-password", "PGDATABASE" => "tailor_shop_ledger_production" } }
  let(:dump) { [ "pg_dump", "--format=custom", "--file=#{path}" ] }
  let(:upload) do
    [ "curl", "--config", "-", "--aws-sigv4", "aws:amz:auto:s3", "--upload-file", path, "https://account.r2.cloudflarestorage.com/backups/tailor_shop_ledger_production-20261016T080000Z.dump",
      "--fail-with-body", "--silent", "--show-error", "--retry", "3" ]
  end
  let(:keys) { %(user = "key-id:secret-key") }
  let(:dumped) { instance_double(Process::Status, success?: true) }
  let(:uploaded) { instance_double(Process::Status, success?: true) }

  before do
    allow(Dir).to receive(:mktmpdir).and_yield("/tmp/backup")
    allow(Open3).to receive(:capture2e).with(environment, *dump).and_return([ "", dumped ])
    allow(Open3).to receive(:capture2e).with({}, *upload, stdin_data: keys).and_return([ "", uploaded ])
  end

  it { is_expected.to eq "tailor_shop_ledger_production-20261016T080000Z.dump" }

  it "dumps the database with its password in the environment" do
    call

    expect(Open3).to have_received(:capture2e).with(environment, *dump)
  end

  it "uploads the dump to R2 with the keys through stdin" do
    call

    expect(Open3).to have_received(:capture2e).with({}, *upload, stdin_data: keys)
  end

  context "when pg_dump fails" do
    let(:dumped) { instance_double(Process::Status, success?: false) }

    before { allow(Open3).to receive(:capture2e).with(environment, *dump).and_return([ "pg_dump: error: connection refused", dumped ]) }

    it "raises with its output and uploads nothing" do
      expect { call }.to raise_error(RuntimeError, "pg_dump failed: pg_dump: error: connection refused")
      expect(Open3).not_to have_received(:capture2e).with({}, *upload, stdin_data: keys)
    end
  end

  context "when the upload fails" do
    let(:uploaded) { instance_double(Process::Status, success?: false) }

    before { allow(Open3).to receive(:capture2e).with({}, *upload, stdin_data: keys).and_return([ "<Code>SignatureDoesNotMatch</Code>", uploaded ]) }

    it { expect { call }.to raise_error(RuntimeError, "curl failed: <Code>SignatureDoesNotMatch</Code>") }
  end
end
