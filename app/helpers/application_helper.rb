module ApplicationHelper
  # The shop's name once signed in, the app's before.
  def header_title
    current_tenant&.name || t("app_name")
  end

  # The tab bar and the account button.
  def signed_in_navigation
    render "layouts/navigation" if authenticated?
  end

  # A tab of the tab bar, marked when its page is the one shown. A tab whose page isn't built yet has no path,
  # and shows without a link.
  def tab_to(label, path, &icon)
    content = safe_join([ capture(&icon), label ])
    return tag.span(content, class: "tab") unless path

    link_to content, path, class: "tab", aria: { current: aria_current(path) }
  end

  def aria_current(path)
    "page" if current_page?(path)
  end

  # "Martes 20 de octubre" in es-CO, whose day names are lowercase; "Tuesday, October 20" in en.
  def day_title(date)
    l(date, format: :day).upcase_first
  end

  def flash_messages
    safe_join(flash.map { |type, message| tag.p(message, class: "flash-#{type}", role: "status") })
  end

  def field_error(record, attribute)
    return if record.errors[attribute].none?

    tag.p(record.errors.full_messages_for(attribute).to_sentence, class: "field-error")
  end
end
