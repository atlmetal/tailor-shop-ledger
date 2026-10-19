# A result always shows its word and icon, never its color alone.
module ResultsHelper
  # The word's text and icon in each size: medium in Today's month panel, large in Reports' result panel.
  WORD_SIZES = { medium: [ "gap-2 text-note font-bold", "size-5.5" ], large: [ "gap-2 font-extrabold", "size-6" ] }.freeze

  # "Ganancia" with a check from 0 up, "Pérdida" with an alert below it.
  def result_word(result, size: :medium)
    text_class, icon_class = WORD_SIZES.fetch(size)
    render(result.total.negative? ? "shared/loss_word" : "shared/profit_word", text_class:, icon_class:)
  end

  # The word alone, on a line that already carries the amount and its color: the end of Reports' calculation.
  def result_name(result)
    t(result.total.negative? ? "shared.loss_word.text" : "shared.profit_word.text")
  end

  def result_amount_class(result)
    "text-loss-ink" if result.total.negative?
  end

  # Tinted yellow for a profit, red for a loss.
  def result_panel_class(result)
    result.total.negative? ? "result-loss" : "result-profit"
  end
end
