require "rails_helper"

RSpec.describe EntriesHelper, type: :helper do
  describe "#entry_path_for" do
    it { expect(helper.entry_path_for(instance_double(Entry, kind: "income", new_record?: true))).to eq("/incomes") }
    it { expect(helper.entry_path_for(instance_double(Entry, kind: "expense", new_record?: false, to_param: "7"))).to eq("/expenses/7") }
  end

  describe "#edit_entry_path_for" do
    it { expect(helper.edit_entry_path_for(instance_double(Entry, kind: "income", to_param: "7"))).to eq("/incomes/7/edit") }
  end

  describe "#latest_entries" do
    it { expect(helper.latest_entries([], kind: "expense")).to be_nil }
  end
end
