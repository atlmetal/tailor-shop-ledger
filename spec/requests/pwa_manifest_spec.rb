require "rails_helper"

RSpec.describe "PWA manifest", type: :request do
  # Browsers fetch the manifest without the session cookie.
  before { get pwa_manifest_path(format: :json) }

  it { expect(response.parsed_body).to include("name" => "Tailor Shop Ledger", "start_url" => "/", "display" => "standalone") }

  it "offers each icon size for any use and as maskable" do
    expect(response.parsed_body["icons"].pluck("src", "sizes", "purpose")).to contain_exactly(
      [ "/icon-192.png", "192x192", nil ], [ "/icon-512.png", "512x512", nil ],
      [ "/icon-192.png", "192x192", "maskable" ], [ "/icon-512.png", "512x512", "maskable" ]
    )
  end
end
