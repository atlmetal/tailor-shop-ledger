# Expenses and other income are both entries, so their paths come from the kind: /expenses or /incomes.
module EntriesHelper
  def entry_path_for(entry)
    entry.new_record? ? public_send(:"#{entry.kind.pluralize}_path") : public_send(:"#{entry.kind}_path", entry)
  end

  def edit_entry_path_for(entry)
    public_send(:"edit_#{entry.kind}_path", entry)
  end

  # The last ten of a kind, each opening its form; nothing until there's one.
  def latest_entries(entries, kind:)
    render("entries/latest", entries:, kind:) if entries.present?
  end
end
