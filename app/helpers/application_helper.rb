module ApplicationHelper
  # The shop's name once signed in, the app's before.
  def header_title
    current_tenant&.name || t("app_name")
  end

  # The tab bar and the account button.
  def signed_in_navigation
    render "layouts/navigation" if authenticated?
  end

  # A tab of the tab bar, marked when its page is the one shown, or one of the paths `also` gives. A tab whose
  # page isn't built yet has no path, and shows without a link.
  def tab_to(label, path, also: nil, &icon)
    content = safe_join([ capture(&icon), label ])
    return tag.span(content, class: "tab") unless path

    link_to content, path, class: "tab", aria: { current: aria_current(path, *also) }
  end

  # A link marks its whole section: Taller's link to /services also marks /services/12/edit. By path rather
  # than current_page?, which only matches GET requests and so would drop the mark when a form comes back
  # with its errors.
  def aria_current(*paths)
    "page" if paths.any? { request.path == it || request.path.start_with?("#{it}/") }
  end

  # A form folded in a <details>, which comes back open when it failed, to show its errors.
  def form_details(form, **options, &)
    tag.details(open: form.errors.any?, **options, &)
  end

  # Whole pesos, $15.000 in es-CO and $15,000 in en, with a true minus sign: −$47.000.
  def pesos(amount)
    "#{"−" if amount.negative?}#{number_to_currency(amount.abs, precision: 0)}"
  end

  # A pesos field with the "$" before it, which takes digits only and groups them as the user types.
  def money_field(form, attribute, **options)
    tag.div(class: "money-field") do
      safe_join([
        tag.span(t("number.currency.format.unit"), class: "font-normal text-graphite", aria: { hidden: true }),
        form.text_field(attribute, value: number_with_delimiter(form.object.public_send(attribute)), inputmode: "numeric", autocomplete: "off",
          data: { controller: "money-field", action: "money-field#format", money_field_delimiter_value: t("number.currency.format.delimiter") }, **options)
      ])
    end
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
