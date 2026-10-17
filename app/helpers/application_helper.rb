module ApplicationHelper
  def field_error(record, attribute)
    return if record.errors[attribute].none?

    tag.p(record.errors.full_messages_for(attribute).to_sentence, class: "field-error")
  end
end
