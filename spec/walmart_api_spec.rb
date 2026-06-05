# frozen_string_literal: true

RSpec.describe WalmartApi do
  it "has a version number" do
    expect(WalmartApi::VERSION).to eq("0.1.0")
  end

  it "loads the WalmartApi module" do
    expect(described_class).to be_a(Module)
  end
end
